import sys
import shutil
import zipfile
import os
from datetime import datetime
from pathlib import Path

from PyQt6.QtWidgets import (
QApplication, QMainWindow, QFileDialog, QMessageBox,
QDialog, QVBoxLayout, QLabel, QPushButton, QTextEdit, QListWidgetItem
)

from PyQt6.uic import loadUi
from PyQt6.QtCore import Qt

from config_manager import ConfigManager
from configparser import ConfigParser


class FactoryTools(QMainWindow):
    def __init__(self):
        super().__init__()
        ui_path = Path(__file__).parent / "FactoryMgr.ui"
        loadUi(ui_path, self)

# Load default factory folder from ~/.freefactoryrc
        config = ConfigParser()
        config.read(os.path.expanduser("~/.freefactoryrc"))
        if config.has_section("global") and config.has_option("global", "FactoryLocation"):
            default_factory_path = config.get("global", "FactoryLocation")
            if default_factory_path:
                self.PathtoFactoryFolders.setText(default_factory_path)







        if default_factory_path:
            self.PathtoFactoryFolders.setText(default_factory_path)






        self.config = ConfigManager()
        
        self.ImportFactory.clicked.connect(self.import_factory)
        self.ExportFactory.clicked.connect(self.export_factory)
        self.BackupFactories.clicked.connect(self.backup_factories)
        self.CheckFactoryIntegrity.clicked.connect(self.check_factory_integrity)
        self.CheckNotifyDuplicates.clicked.connect(self.check_notify_duplicates)
        self.listFactoryFiles.itemDoubleClicked.connect(self.preview_factory)
        self.refresh_factory_list()
        self.CommitChanges.clicked.connect(self.run_migration)
        self.buttonSelectFactoryDir.clicked.connect(self.select_factory_folder)
        self.RefreshList.clicked.connect(self.refresh_factory_list)


    def select_factory_folder(self):
        self.factory_dir = Path(self.PathtoFactoryFolders.text().strip())
        folder = QFileDialog.getExistingDirectory(self, "Select Factory Folder")
        if folder:
            self.PathtoFactoryFolders.setText(folder)





    def import_factory(self):
        file_dialog = QFileDialog(self)
        file_dialog.setWindowTitle("Select a Factory File to Import")
        file_dialog.setNameFilter("Factory files (*)")
        if file_dialog.exec():
            selected_file = Path(file_dialog.selectedFiles()[0])
            destination = self.factory_dir / selected_file.name

            if destination.exists():
                reply = QMessageBox.question(
                    self, "Overwrite Factory?",
                    f"{selected_file.name} already exists. Overwrite?",
                    QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
                )
                if reply != QMessageBox.StandardButton.Yes:
                    return

            try:
                shutil.copy(selected_file, destination)
                QMessageBox.information(self, "Import Successful", f"Imported: {selected_file.name}")
            except Exception as e:
                QMessageBox.critical(self, "Import Failed", str(e))

    def export_factory(self):
        file_dialog = QFileDialog(self)
        file_dialog.setWindowTitle("Save Factory As")
        file_dialog.setAcceptMode(QFileDialog.AcceptMode.AcceptSave)
        file_dialog.setNameFilter("Factory files (*)")
        if file_dialog.exec():
            selected_file = Path(file_dialog.selectedFiles()[0])

            save_path, _ = QFileDialog.getSaveFileName(
                self, "Export Factory As", selected_file.name, "Factory Files (*.factory)"
            )
            if not save_path:
                return

            try:
                with open(selected_file, "r") as f:
                    lines = f.readlines()

                stripped_lines = []
                skip_keys = [
                    "NOTIFYDIRECTORY", "OUTPUTDIRECTORY",
                    "STREAMRTMPURL", "STREAMKEY"
                ]

                for line in lines:
                    if not line.strip():
                        stripped_lines.append(line)
                        continue
                    key = line.split("=", 1)[0].strip()
                    if key in skip_keys:
                        stripped_lines.append(f"{key}=\n")
                    else:
                        stripped_lines.append(line)

                with open(save_path, "w") as f:
                    f.writelines(stripped_lines)

                QMessageBox.information(self, "Export Successful", f"Exported to: {save_path}")
            except Exception as e:
                QMessageBox.critical(self, "Export Failed", str(e))

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

                # Skip comments and blank lines
                if not stripped or stripped.startswith("#"):
                    continue

                # Split and validate key/value format
                if "=" not in stripped:
                    issues.append(f"{factory_path.name}, Line {lineno}: Missing '=' → {stripped}")
                    continue

                key, value = map(str.strip, stripped.split("=", 1))

                # Key validations
                if not key:
                    issues.append(f"{factory_path.name}, Line {lineno}: Empty key before '=' → {stripped}")
                elif " " in key:
                    issues.append(f"{factory_path.name}, Line {lineno}: Key contains space → {key}")

                # NEW: Check if value is wrapped in quotes (and not just "")
                if value.startswith('"') and value.endswith('"') and len(value) > 2:
                    issues.append(f"{factory_path.name}, Line {lineno}: Value appears to be quoted → {value}")


        # Show results
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
                                    if path in notify_map:
                                        notify_map[path].append(file.name)
                                    else:
                                        notify_map[path] = [file.name]
                                break  # Stop reading after finding NOTIFYDIRECTORY
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
        self.factory_dir = Path(self.PathtoFactoryFolders.text().strip())
        factory_dir = Path(self.PathtoFactoryFolders.text().strip())
        if not factory_dir.is_dir():
            QMessageBox.warning(self, "Error", f"Factory path not found: {factory_dir}")
            return

        self.listFactoryFiles.clear()
        for path in sorted(factory_dir.glob("*")):
            if path.is_file():
                self.listFactoryFiles.addItem(path.name)


    def preview_factory(self, item):
        factory_path = self.factory_dir / item.text()
        if not factory_path.exists():
            return

        try:
            with open(factory_path, 'r') as f:
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

    def select_factory_dir(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Factory Directory")
        if directory:
            self.PathtoFactoryFolders.setText(directory)



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

        # Parse input lines depending on the operation
        add_keys = {}
        set_keys = {}
        remove_keys = []
        rename_pairs = {}


        # Only check once if any .bak files exist in the target directory
        existing_baks = list(factory_dir.glob("*.bak"))
        overwrite_backups = True  # default behavior

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
                            if backup_path.exists():
                                reply = QMessageBox.question(
                                    self,
                                    "Backup Exists",
                                    f"A backup file already exists:\n\n{backup_path.name}\n\nOverwrite it?",
                                    QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
                                )
                                if reply != QMessageBox.StandardButton.Yes:
                                    continue  # Skip this file and go to the next

                            shutil.copy2(path, backup_path)

                            
                            
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

        self.refresh_factory_list()





            


if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = FactoryTools()
    window.show()
    sys.exit(app.exec())
