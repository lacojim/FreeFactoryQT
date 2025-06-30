# droptextedit.py
# This keeps track of dropped files and paths for dropZone only. Not the file queue

from PyQt6.QtWidgets import QPlainTextEdit
from PyQt6.QtCore import pyqtSignal, QUrl, Qt

# droptextedit.py
from PyQt6.QtWidgets import QPlainTextEdit
from PyQt6.QtCore import pyqtSignal, QUrl, Qt

class DropTextEdit(QPlainTextEdit):
    filesDropped = pyqtSignal(list)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setAcceptDrops(True)

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()

    def dropEvent(self, event):
        urls = event.mimeData().urls()
        file_paths = [url.toLocalFile() for url in urls if url.isLocalFile()]
        self.filesDropped.emit(file_paths)

