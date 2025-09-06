import sys
import shutil
import zipfile
import os
from datetime import datetime
from pathlib import Path

from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QFileDialog, QMessageBox,
    QDialog, QVBoxLayout, QLabel, QPushButton, QTextEdit, QListWidgetItem,
    QAbstractItemView
)
from PyQt6.uic import loadUi
from PyQt6.QtCore import Qt

from config_manager import ConfigManager
from configparser import ConfigParser
from version import get_version


README_TEXT = """FreeFactory Export Folder

This folder is the default destination for exported factories.

• When exporting WITHOUT zip: cleaned factory files are written here, using their base
  filename. If a name exists, '-export-N' is appended.

• When exporting TO zip: a single ZIP archive is written here. Inside the archive, each
  entry uses the base filename. Duplicates get '-export-N'.

You can change the export destination at export time; this folder is just the default.
"""


class FactoryTools(QMainWindow):
    def __init__(self):
        super().__init__()
        ui_path = Path(__file__).parent / "FactoryMgr.ui"
        loadUi(ui_path, self)

        # Load default factory folder from ~/.freefactoryrc
        default_factory_path = ""
        config = ConfigParser()
        config.read(os.path.expanduser("~/.freefactoryrc"))
        if config.has_section("global") and config.has_option("global", "FactoryLocation"):
            default_factory_path = config.get("global", "FactoryLocation")
            if default_factory_path:
                self.PathtoFactoryFolders.setText(default_factory_path)

        self.config = ConfigManager()
        self.factory_dir = Path(self.PathtoFactoryFolders.text().strip() or (self.config.get("FactoryLocation") or "/opt/FreeFactory/Factories"))

        # Enable multi-select for list (CTRL/SHIFT selection)
        self.listFactoryFiles.setSelectionMode(QAbstractItemView.SelectionMode.ExtendedSelection)
        self.listFactoryFiles.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectItems)

        # Wire up buttons
        self.ImportFactory.clicked.connect(self.import_factory)
        self.ExportFactory.clicked.connect(self.export_factory)
        self.BackupFactories.clicked.connect(self.backup_factories)
        self.CheckFactoryIntegrity.clicked.connect(self.check_factory_integrity)
        self.CheckNotifyDuplicates.clicked.connect(self.check_notify_duplicates)
        self.listFactoryFiles.itemDoubleClicked.connect(self.preview_factory)
        self.CommitChanges.clicked.connect(self.run_migration)
        self.buttonSelectFactoryDir.clicked.connect(self.select_factory_folder)
        self.RefreshList.clicked.connect(self.refresh_factory_list)
        
        self.setWindowTitle(f"FreeFactory FactoryTools - {get_version()}")

        # Initial population
        self.refresh_factory_list()

    # ---------- Path helpers ----------
    
    def _is_pathlike_value(self, v: str) -> bool:
            """
            Heuristics to decide if a value looks like a filesystem path/filename.
            We treat the following as *non-path* and thus keep them:
            - lavfi-style key=val (e.g., 'color=black:s=1280x720')
            - display/dev strings like ':0.0', 'default', 'hw:0', 'alsa', 'pulse', 'jack'
            - network/protocol sources: 'rtsp://', 'srt://', 'udp://', 'tcp://', 'http://', 'https://'
            Everything else that looks like an absolute/relative path, Windows path,
            'file:' URL, or has a likely file extension is treated as path-like.
            """
            if not v:
                return False
            s = v.strip()

            # Non-path patterns to KEEP as-is
            if s.startswith(":"):  # e.g., ':0.0' (x11 display)
                return False
            if s in {"default", "pulse", "alsa", "jack"}:
                return False
            if s.startswith(("hw:", "jack:")):
                return False
            if "=" in s and s.split("=", 1)[0].isalnum():  # e.g., 'color=...', 'testsrc=...'
                return False
            if s.lower().startswith(("rtsp://", "srt://", "udp://", "tcp://", "http://", "https://")):
                return False

            # Clear path-like patterns
            if s.startswith(("/", "./", "../", "~/")):
                return True
            if s.lower().startswith("file:"):
                return True
            # Windows drive (won't occur on Fedora, but harmless to support)
            import re
            if re.match(r"^[A-Za-z]:[\\/]", s):
                return True

            # Has directory separators?
            if "/" in s or "\\" in s:
                return True

            # Looks like a filename with an extension (e.g., 'clip.mp4', 'audio.wav')
            if re.search(r"\.[A-Za-z0-9]{2,4}$", s):
                return True

            return False
    

    def _update_factory_dir_from_ui(self):
        self.factory_dir = Path(self.PathtoFactoryFolders.text().strip() or (self.config.get("FactoryLocation") or "/opt/FreeFactory/Factories"))

    def _unique_path(self, path: Path, tag: str) -> Path:
        """Return a non-overwriting path by appending -{tag}-N before extension (or at end if no ext)."""
        if not path.exists():
            return path
        base = path.stem if path.suffix else path.name
        ext = path.suffix
        counter = 1
        while True:
            candidate = path.with_name(f"{base}-{tag}-{counter}{ext}")
            if not candidate.exists():
                return candidate
            counter += 1

    def _default_export_dir(self) -> Path:
        """
        Preferred default: /opt/FreeFactory/export
        Fallback if not writable/creatable: ~/FreeFactory/export
        Ensure existence and drop a readme.txt once.
        """
        preferred = Path("/opt/FreeFactory/export")
        fallback = Path.home() / "FreeFactory" / "export"

        def ensure_dir(p: Path) -> bool:
            try:
                p.mkdir(parents=True, exist_ok=True)
                # write README if missing
                readme = p / "readme.txt"
                if not readme.exists():
                    readme.write_text(README_TEXT, encoding="utf-8")
                # quick writability probe
                probe = p / ".write_test"
                probe.write_text("ok", encoding="utf-8")
                probe.unlink(missing_ok=True)
                return True
            except Exception:
                return False

        if ensure_dir(preferred):
            return preferred
        if ensure_dir(fallback):
            # Nudge user once if we fell back
            QMessageBox.information(
                self, "Export Folder",
                f"Could not use {preferred} (permission?). Falling back to:\n{fallback}"
            )
            return fallback
        # Last resort: home dir
        home = Path.home()
        home.mkdir(parents=True, exist_ok=True)
        QMessageBox.warning(self, "Export Folder", f"Falling back to home: {home}")
        return home


    # ---------- Import helpers ----------
    def _files_identical(self, a: Path, b: Path) -> bool:
        try:
            if a.stat().st_size != b.stat().st_size:
                return False
            import hashlib
            def sha256(p: Path) -> str:
                h = hashlib.sha256()
                with p.open("rb") as f:
                    for chunk in iter(lambda: f.read(1024 * 1024), b""):
                        h.update(chunk)
                return h.hexdigest()
            return sha256(a) == sha256(b)
        except Exception:
            return False

    def _unique_import_dest(self, dest: Path) -> Path | None:
        """
        Return a destination path that won't overwrite.
        - If dest doesn't exist -> dest
        - If dest exists and is identical -> None (signal to skip)
        - Else try base-import, base-import-2, ... (before extension if present)
        """
        if not dest.exists():
            return dest
        # identical? skip
        try:
            # Write temp file outside; caller compares source vs dest instead.
            pass
        except Exception:
            pass
        # base parts
        base = dest.stem if dest.suffix else dest.name
        ext = dest.suffix
        # First try "-import"
        candidate = dest.with_name(f"{base}-import{ext}")
        if candidate.exists():
            # bump counter
            i = 2
            while True:
                candidate = dest.with_name(f"{base}-import-{i}{ext}")
                if not candidate.exists():
                    break
                i += 1
        return candidate



    # ---------- Cleaning ----------

    def _clean_factory_content(self, text: str) -> str:
            """
            Portable export cleaning with path-aware placeholders.
            - For path/filename fields, if value is path-like → replace with '/add/path/filename/here'
            (but keep non-path forms like 'color=...' or ':0.0', 'default', 'hw:0', etc.)
            - For instance-specific or deprecated keys, always blank to keep exports portable.
            """

            # Always blank these (instance-specific / deprecated)
            always_blank = {
                "NOTIFYDIRECTORY", "OUTPUTDIRECTORY",
                "STREAMRTMPURL", "STREAMKEY",
                "FACTORYEMAILMESSAGESTART", "FACTORYEMAILMESSAGEEND", "FACTORYLINKS",
                "FTPPROGRAM", "FTPURL", "FTPUSERNAME", "FTPPASSWORD",
                "FTPREMOTEPATH", "FTPTRANSFERTYPE", "FTPDELETEAFTER",
                "PIX_FMT", "VIDEOTAGS", "AUDIOTAG",
            }

            # For these keys, we *conditionally* replace value with a placeholder if it looks path-like.
            pathish_keys = {
                "STREAMINPUTVIDEO", "STREAMINPUTAUDIO",
                "FORCEFORMATINPUTVIDEO", "FORCEFORMATINPUTAUDIO",
                "INPUTFILE", "INPUTVIDEOFILE", "INPUTAUDIOFILE",
                "VIDEOPATH", "AUDIOPATH",
            }

            out_lines = []
            for line in text.splitlines(keepends=True):
                raw = line
                stripped = raw.strip()

                # Keep comments/blank and malformed lines untouched
                if not stripped or stripped.startswith("#") or "=" not in stripped:
                    out_lines.append(raw)
                    continue

                key, val = stripped.split("=", 1)
                key = key.strip()
                val = val.strip()

                # Always blank group
                if key in always_blank:
                    out_lines.append(f"{key}=\n")
                    continue

                # Path-ish placeholders (only when the value truly looks like a path/filename)
                if key in pathish_keys and self._is_pathlike_value(val):
                    out_lines.append(f"{key}=/add/path/filename/here\n")
                    continue

                # Default: keep as-is
                out_lines.append(raw)

            return "".join(out_lines)

    # ---------- UI Slots ----------

    def select_factory_folder(self):
        self._update_factory_dir_from_ui()
        folder = QFileDialog.getExistingDirectory(self, "Select Factory Folder", str(self.factory_dir))
        if folder:
            self.PathtoFactoryFolders.setText(folder)
            self._update_factory_dir_from_ui()
            self.refresh_factory_list()

    def import_factory(self):
        """
        Multi-select import.
        - If target name exists and content is identical, skip.
        - Otherwise, rename to -import/-import-N without prompting.
        """
        self._update_factory_dir_from_ui()
        file_dialog = QFileDialog(self)
        file_dialog.setWindowTitle("Select Factory Files to Import")
        file_dialog.setNameFilter("Factory files (*)")
        file_dialog.setFileMode(QFileDialog.FileMode.ExistingFiles)
        if not file_dialog.exec():
            return

        selected_files = [Path(p) for p in file_dialog.selectedFiles()]
        if not selected_files:
            return

        imported, renamed, skipped_identical, errors = [], [], [], []

        for src in selected_files:
            try:
                dest = self.factory_dir / src.name
                if dest.exists():
                    # identical? skip
                    if self._files_identical(src, dest):
                        skipped_identical.append(dest.name)
                        continue
                    # different -> pick unique -import/-import-N
                    unique_dest = self._unique_import_dest(dest)
                    if unique_dest is None:
                        skipped_identical.append(dest.name)
                        continue
                    shutil.copy2(src, unique_dest)
                    imported.append(unique_dest.name)
                    renamed.append(f"{src.name} → {unique_dest.name}")
                else:
                    shutil.copy2(src, dest)
                    imported.append(dest.name)
            except Exception as e:
                errors.append(f"{src.name}: {e}")

        self.refresh_factory_list()

        # One concise summary
        lines = []
        if imported:
            lines.append(f"Imported: {len(imported)} file(s)")
        if renamed:
            lines.append(f"Renamed {len(renamed)} due to name collisions:")
            lines.extend(f"  • {r}" for r in renamed[:50])
            if len(renamed) > 50:
                lines.append("  …")
        if skipped_identical:
            lines.append(f"Skipped (identical already present): {len(skipped_identical)}")
        if errors:
            lines.append("Errors:")
            lines.extend(f"  • {e}" for e in errors[:50])
            if len(errors) > 50:
                lines.append("  …")

        if lines:
            QMessageBox.information(self, "Import Summary", "\n".join(lines))
        else:
            QMessageBox.information(self, "Import Summary", "No files were imported.")

    def export_factory(self):
        """
        Multi-export for selected factories.
        1) Ask export mode: ZIP vs files.
        2) Ask destination folder (defaults to export folder, but user can change).
        3) Clean each factory and write accordingly (no overwrites).
        """
        self._update_factory_dir_from_ui()
        items = self.listFactoryFiles.selectedItems()
        if not items:
            QMessageBox.warning(self, "No Selection", "Select one or more factories in the list to export.")
            return

        # Ask ZIP or plain files
        choice = QMessageBox.question(
            self, "Export Mode",
            "Export selected factories as a single ZIP archive?\n\n"
            "Yes = ZIP archive\nNo = Individual files\nCancel = Abort",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No | QMessageBox.StandardButton.Cancel
        )
        if choice == QMessageBox.StandardButton.Cancel:
            return
        as_zip = (choice == QMessageBox.StandardButton.Yes)

        # Choose (or confirm) destination folder; default to export folder
        export_root = self._default_export_dir()
        target_dir = QFileDialog.getExistingDirectory(
            self, "Select Export Destination", str(export_root)
        )
        if not target_dir:
            return
        export_dir = Path(target_dir)

        # Gather sources
        sources = []
        for item in items:
            src_path = self.factory_dir / item.text()
            if not src_path.is_file():
                QMessageBox.warning(self, "Missing File", f"Not a file: {src_path}")
                continue
            sources.append(src_path)
        if not sources:
            return

        if as_zip:
            self._export_as_zip(sources, export_dir)
        else:
            self._export_as_files(sources, export_dir)

    def _export_as_files(self, source_paths: list[Path], export_dir: Path):
        exported, errors = [], []
        for src_path in source_paths:
            try:
                raw = src_path.read_text(encoding="utf-8", errors="ignore")
                cleaned = self._clean_factory_content(raw)

                base_name = src_path.name
                #if base_name.endswith(".factory"):
                #    base_name = base_name[:-9]  # drop literal .factory

                dest = export_dir / base_name
                if dest.exists():
                    dest = self._unique_path(dest, "export")

                dest.write_text(cleaned, encoding="utf-8")
                exported.append(dest.name)
            except Exception as e:
                errors.append(f"{src_path.name}: {e}")

        if exported:
            QMessageBox.information(
                self, "Export Complete",
                f"Wrote {len(exported)} file(s) to:\n{export_dir}\n\n" +
                "\n".join(exported[:50]) + ("" if len(exported) <= 50 else "\n..."))
        if errors:
            QMessageBox.warning(
                self, "Some Exports Failed",
                "\n".join(errors[:50]) + ("" if len(errors) <= 50 else "\n..."))

    def _export_as_zip(self, source_paths: list[Path], export_dir: Path):
        # Pick a default name and ensure uniqueness
        ts = datetime.now().strftime("%Y-%m-%d_%H%M%S")
        default_zip = export_dir / f"Factories-Export-{ts}.zip"
        zip_path_str, _ = QFileDialog.getSaveFileName(
            self, "Save Export ZIP As", str(default_zip), "ZIP Archives (*.zip)"
        )
        if not zip_path_str:
            return
        zip_path = Path(zip_path_str)
        if zip_path.exists():
            zip_path = self._unique_path(zip_path, "export")

        exported_names = []
        name_set = set()
        errors = []

        try:
            with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
                for src_path in source_paths:
                    try:
                        raw = src_path.read_text(encoding="utf-8", errors="ignore")
                        cleaned = self._clean_factory_content(raw)

                        base_name = src_path.name
                        #if base_name.endswith(".factory"):
                        #    base_name = base_name[:-9]

                        # ensure unique names inside the ZIP
                        name = base_name
                        if name in name_set:
                            counter = 1
                            while f"{base_name}-export-{counter}" in name_set:
                                counter += 1
                            name = f"{base_name}-export-{counter}"
                        name_set.add(name)

                        # write directly from memory
                        zf.writestr(name, cleaned)
                        exported_names.append(name)
                    except Exception as e:
                        errors.append(f"{src_path.name}: {e}")
        except Exception as e:
            QMessageBox.critical(self, "ZIP Export Failed", str(e))
            return

        if exported_names:
            QMessageBox.information(
                self, "ZIP Export Complete",
                f"Wrote {len(exported_names)} cleaned factories into:\n{zip_path}\n\n" +
                "\n".join(exported_names[:50]) + ("" if len(exported_names) <= 50 else "\n..."))
        if errors:
            QMessageBox.warning(
                self, "Some Exports Failed",
                "\n".join(errors[:50]) + ("" if len(errors) <= 50 else "\n..."))

    def backup_factories(self):
        factory_dir = self.config.get("FactoryLocation") or "/opt/FreeFactory/Factories"
        factory_path = Path(factory_dir)

        if not factory_path.exists():
            QMessageBox.critical(self, "Backup Failed", f"Factory path does not exist:\n{factory_path}")
            return

        # Match only extensionless files
        factory_files = [f for f in factory_path.iterdir() if f.is_file() and not f.suffix]

        if not factory_files:
            QMessageBox.critical(self, "Backup Failed", f"No factory files found in:\n{factory_path}")
            return

        today_str = datetime.now().strftime("%Y-%m-%d")
        default_name = f"Factories-Backup-{today_str}.zip"
        save_path, _ = QFileDialog.getSaveFileName(
            self, "Save Backup As", str(Path.home() / default_name), "ZIP Archives (*.zip)"
        )
        if not save_path:
            return

        try:
            with zipfile.ZipFile(save_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for f in factory_files:
                    zipf.write(f, arcname=f.name)

            QMessageBox.information(self, "Backup Successful", f"Backup saved to:\n{save_path}")
        except Exception as e:
            QMessageBox.critical(self, "Backup Failed", str(e))

    def check_factory_integrity(self):
        factory_dir = Path(self.config.get("FactoryLocation") or "/opt/FreeFactory/Factories")
        factory_files = sorted(factory_dir.glob("*"))  # no suffix filter

        issues = []
        for factory_path in factory_files:
            if not factory_path.is_file():
                continue

            with factory_path.open("r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()

            for lineno, line in enumerate(lines, start=1):
                stripped = line.strip()
                if not stripped or stripped.startswith("#"):
                    continue
                if "=" not in stripped:
                    issues.append(f"{factory_path.name}, Line {lineno}: Missing '=' → {stripped}")
                    continue

                key, value = map(str.strip, stripped.split("=", 1))
                if not key:
                    issues.append(f"{factory_path.name}, Line {lineno}: Empty key before '=' → {stripped}")
                elif " " in key:
                    issues.append(f"{factory_path.name}, Line {lineno}: Key contains space → {key}")

                if value.startswith('"') and value.endswith('"') and len(value) > 2:
                    issues.append(f"{factory_path.name}, Line {lineno}: Value appears to be quoted → {value}")

        if issues:
            QMessageBox.warning(self, "Factory Integrity Issues", "\n".join(issues[:100]) + ("\n... (more)" if len(issues) > 100 else ""))
        else:
            QMessageBox.information(self, "Integrity Check", "All factory files appear to be valid.")

    def check_notify_duplicates(self):
        factory_dir = Path(self.config.get("FactoryLocation") or "/opt/FreeFactory/Factories")
        notify_map = {}
        duplicates = []

        for file in factory_dir.glob("*"):
            if file.is_file():
                try:
                    with file.open("r", encoding="utf-8") as f:
                        for line in f:
                            if line.startswith("NOTIFYDIRECTORY="):
                                path = line.strip().split("=", 1)[-1]
                                if path:
                                    notify_map.setdefault(path, []).append(file.name)
                                break
                except Exception as e:
                    duplicates.append(f"{file.name}: Error reading file - {str(e)}")

        for path, files in notify_map.items():
            if len(files) > 1:
                duplicates.append(f"{path} used in: {', '.join(files)}")

        if duplicates:
            QMessageBox.warning(self, "Duplicate NOTIFYDIRECTORY", "Conflicts found:\n" + "\n".join(duplicates[:100]))
        else:
            QMessageBox.information(self, "Duplicate NOTIFYDIRECTORY", "No duplicate NOTIFYDIRECTORY values found.")

    def refresh_factory_list(self):
        self._update_factory_dir_from_ui()
        if not self.factory_dir.is_dir():
            QMessageBox.warning(self, "Error", f"Factory path not found: {self.factory_dir}")
            return

        self.listFactoryFiles.clear()
        for path in sorted(self.factory_dir.glob("*")):
            if path.is_file():
                self.listFactoryFiles.addItem(path.name)

    def preview_factory(self, item):
        factory_path = self.factory_dir / item.text()
        if not factory_path.exists():
            return

        try:
            with open(factory_path, 'r', encoding="utf-8", errors="ignore") as f:
                content = f.read()
        except Exception as e:
            content = f"Failed to read factory file:\n{str(e)}"

        dialog = QDialog(self)
        dialog.setWindowTitle(f"Preview: {item.text()}")
        dialog.setMinimumSize(600, 400)
        layout = QVBoxLayout()

        text_edit = QTextEdit()
        text_edit.setPlainText(content)
        text_edit.setReadOnly(True)
        layout.addWidget(text_edit)

        close_btn = QPushButton("Close")
        close_btn.clicked.connect(dialog.accept)
        layout.addWidget(close_btn, alignment=Qt.AlignmentFlag.AlignCenter)

        dialog.setLayout(layout)
        dialog.exec()

    def run_migration(self):
        operation = None
        raw_text = ""
        if self.AddKeys.text().strip():
            operation = "add"
            raw_text = self.AddKeys.text().strip()
        elif self.SetKeys.text().strip():
            operation = "set"
            raw_text = self.SetKeys.text().strip()
        elif self.RemoveKeys.text().strip():
            operation = "remove"
            raw_text = self.RemoveKeys.text().strip()
        elif self.RenameKeys.text().strip():
            operation = "rename"
            raw_text = self.RenameKeys.text().strip()
        else:
            QMessageBox.warning(self, "No Operation Specified", "Please fill in at least one key field.")
            return

        dry_run = self.checkDryRun.isChecked()
        create_backup = self.checkCreateBackups.isChecked()

        factory_dir = Path(self.PathtoFactoryFolders.text().strip())
        if not factory_dir.is_dir():
            QMessageBox.warning(self, "Error", f"Factory path not found: {factory_dir}")
            return

        add_keys = {}
        set_keys = {}
        remove_keys = []
        rename_pairs = {}

        existing_baks = list(factory_dir.glob("*.bak"))
        if existing_baks:
            reply = QMessageBox.question(
                self,
                "Backup Files Exist",
                "Some backup files (*.bak) already exist in this folder.\n\n"
                "Do you want to overwrite them?",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.Cancel
            )
            if reply != QMessageBox.StandardButton.Yes:
                QMessageBox.information(self, "Migration Canceled", "No changes were made.")
                return

        for line in raw_text.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            if operation in ["add", "set"]:
                if "=" not in line:
                    QMessageBox.warning(self, "Invalid Format", f"Missing '=' in line: {line}")
                    return
                key, value = line.split("=", 1)
                if not key.strip():
                    QMessageBox.warning(self, "Invalid Format", f"Key is empty in line: {line}")
                    return
                if operation == "add":
                    add_keys[key.strip()] = value.strip()
                else:
                    set_keys[key.strip()] = value.strip()

            elif operation == "remove":
                key = line.split("=", 1)[0].strip()
                if not key:
                    QMessageBox.warning(self, "Invalid Format", f"Key name cannot be empty in: {line}")
                    return
                remove_keys.append(key)

            elif operation == "rename":
                if "=" not in line:
                    QMessageBox.warning(self, "Invalid Format", f"Missing '=' in rename line: {line}")
                    return
                old_key, new_key = line.split("=", 1)
                if not old_key.strip() or not new_key.strip():
                    QMessageBox.warning(self, "Invalid Format", f"Invalid rename line: {line}")
                    return
                rename_pairs[old_key.strip()] = new_key.strip()

        factory_files = sorted(factory_dir.glob("*"))
        changed_files = []

        for path in factory_files:
            try:
                with path.open("r", encoding="utf-8") as f:
                    lines = f.readlines()

                modified = False
                new_lines = []

                for line in lines:
                    stripped = line.strip()
                    if not stripped or stripped.startswith("#"):
                        new_lines.append(line)
                        continue

                    parts = stripped.split("=", 1)
                    if len(parts) != 2:
                        new_lines.append(line)
                        continue

                    k, v = parts[0].strip(), parts[1].strip()

                    if operation == "remove" and k in remove_keys:
                        modified = True
                        continue
                    elif operation == "set" and k in set_keys:
                        new_lines.append(f"{k}={set_keys[k]}\n")
                        modified = True
                        continue
                    elif operation == "rename" and k in rename_pairs:
                        new_lines.append(f"{rename_pairs[k]}={v}\n")
                        modified = True
                        continue

                    new_lines.append(line)

                if operation == "add":
                    for k, v in add_keys.items():
                        if not any(l.strip().startswith(f"{k}=") for l in lines):
                            new_lines.append(f"{k}={v}\n")
                            modified = True

                if modified:
                    changed_files.append(str(path.name))
                    if not dry_run:
                        if create_backup:
                            backup_path = path.with_suffix(".bak")
                            shutil.copy2(path, backup_path)
                        with path.open("w", encoding="utf-8") as f:
                            f.writelines(new_lines)

            except Exception as e:
                QMessageBox.warning(self, "Error", f"{path.name} failed: {e}")

        if dry_run:
            msg = "Dry run completed.\n\nThe following factories **would** be modified:\n" + "\n".join(changed_files)
        else:
            msg = "Migration complete.\n\nModified factories:\n" + "\n".join(changed_files)

        if changed_files:
            QMessageBox.information(self, "Factory Migration", msg)
        else:
            QMessageBox.information(self, "Factory Migration", "No changes were made.")


if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = FactoryTools()
    window.show()
    sys.exit(app.exec())
