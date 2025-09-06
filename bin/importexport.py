from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel,
    QLineEdit, QPushButton, QCheckBox, QFileDialog, QMessageBox
)
from PyQt6.QtCore import Qt
from pathlib import Path
import shutil
import zipfile


class ExportFactoryDialog(QDialog):
    def __init__(self, factory_name, factory_path, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Export Factory")
        self.factory_name = factory_name
        self.factory_path = factory_path
        self.selected_path = ""

        self.layout = QVBoxLayout()

        # Export path field
        path_layout = QHBoxLayout()
        self.path_edit = QLineEdit()
        self.browse_btn = QPushButton("Browse")
        self.browse_btn.clicked.connect(self.browse)
        path_layout.addWidget(QLabel("Export to:"))
        path_layout.addWidget(self.path_edit)
        path_layout.addWidget(self.browse_btn)
        self.layout.addLayout(path_layout)

        # Portable Export checkbox
        self.portable_checkbox = QCheckBox("Portable Export (strip system paths, passwords, URLs and Stream Keys)")
        self.layout.addWidget(self.portable_checkbox)

        # Buttons
        btn_layout = QHBoxLayout()
        self.export_btn = QPushButton("Export")
        self.cancel_btn = QPushButton("Cancel")
        self.export_btn.clicked.connect(self.accept)
        self.cancel_btn.clicked.connect(self.reject)
        btn_layout.addStretch()
        btn_layout.addWidget(self.export_btn)
        btn_layout.addWidget(self.cancel_btn)
        self.layout.addLayout(btn_layout)

        self.setLayout(self.layout)
        self.resize(600, 100)

    def browse(self):
        dest_path, _ = QFileDialog.getSaveFileName(self, "Export Factory As", self.factory_name)
        if dest_path:
            self.path_edit.setText(dest_path)

    def get_export_info(self):
        return self.path_edit.text().strip(), self.portable_checkbox.isChecked()


# Function to do the actual export

def export_factory_logic(factory_path: Path, dest_path: Path, portable: bool):
    try:
        lines = factory_path.read_text().splitlines()
        if portable:
            strip_keys = {"NOTIFYDIRECTORY", "OUTPUTDIRECTORY", "STREAMRTMPURL", "STREAMKEY"}
            new_lines = []
            for line in lines:
                if not line.strip():
                    continue
                if "=" in line:
                    key, _ = line.split("=", 1)
                    if key.strip() in strip_keys:
                        continue
                new_lines.append(line)
        else:
            new_lines = lines

        dest_path.write_text("\n".join(new_lines) + "\n")
        return True, f"Exported to: {dest_path}"

    except Exception as e:
        return False, str(e)


def backup_factories_zip(factory_dir: Path, destination_zip: Path):
    try:
        with zipfile.ZipFile(destination_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for factory_file in factory_dir.iterdir():
                if factory_file.is_file():
                    zipf.write(factory_file, arcname=factory_file.name)
        return True, f"Backup created at: {destination_zip}"
    except Exception as e:
        return False, str(e)


