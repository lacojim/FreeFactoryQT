from PyQt6.QtWidgets import QApplication, QMainWindow
from PyQt6.uic import loadUi
from pathlib import Path
import sys

class WidgetInspector(QMainWindow):
    def __init__(self):
        super().__init__()
        ui_path = Path(__file__).parent / "FreeFactory-tabs.ui"
        loadUi(ui_path, self)

        print("\n=== Loaded Widgets ===")
        for name in dir(self):
            if not name.startswith("_"):
                try:
                    w = getattr(self, name)
                    if hasattr(w, 'objectName'):
                        print(f"{name:25} ➜  {type(w).__name__}")
                except Exception:
                    continue

if __name__ == "__main__":
    app = QApplication(sys.argv)
    inspector = WidgetInspector()
    inspector.show()
    sys.exit(app.exec())
