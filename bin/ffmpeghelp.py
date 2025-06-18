# ffmpeghelp.py

from PyQt6.QtWidgets import QDialog, QVBoxLayout, QPlainTextEdit, QPushButton
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QTextOption
from PyQt6.QtWidgets import QLineEdit, QHBoxLayout, QLabel
from PyQt6.QtGui import QFont
import subprocess

class FFmpegHelpDialog(QDialog):
    def __init__(self, title: str, ffmpeg_args: list[str], parent=None):
        super().__init__(parent)

        self.setWindowTitle(title)
        self.setMinimumSize(800, 600)

        layout = QVBoxLayout(self)

# Help Search        
        search_layout = QHBoxLayout()
        search_label = QLabel("Find:")
        self.search_input = QLineEdit()
        #self.search_input.setPlaceholderText("Search...")
        self.search_input.setPlaceholderText("Search (disabled on this system)")
        self.search_input.returnPressed.connect(self.search_text)
        search_layout.addWidget(search_label)
        search_layout.addWidget(self.search_input)
        layout.addLayout(search_layout)
# End Search
        self.text_area = QPlainTextEdit()
        self.text_area.setReadOnly(True)
        self.text_area.setWordWrapMode(QTextOption.WrapMode.NoWrap)
        
# Set monospaced font
        font = QFont("monospace")
        font.setStyleHint(QFont.StyleHint.TypeWriter)
        self.text_area.setFont(font)
        font.setPointSize(12)  # or 11, depending on your preference
        
        #self.text_area.setWordWrapMode(False)
        layout.addWidget(self.text_area)

        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.close)
        layout.addWidget(close_btn, alignment=Qt.AlignmentFlag.AlignRight)
        
        self.run_ffmpeg(ffmpeg_args)

    def run_ffmpeg(self, args):
        try:
            result = subprocess.run(["ffmpeg", "-hide_banner"] + args, capture_output=True, text=True)
            output = result.stdout + "\n" + result.stderr
        except Exception as e:
            output = f"Error running ffmpeg:\n{str(e)}"

        self.text_area.setPlainText(output)
        
    def search_text(self):
        print("[DEBUG] Search disabled for stability. Feature will return in future version.")
#        query = self.search_input.text()
#        if not query:
#            return

#        try:
#            full_text = self.text_area.toPlainText()
#            index = full_text.find(query)

#            if index == -1:
#                print(f"[DEBUG] '{query}' not found.")
#                return

            # Estimate line number by counting newlines
#            line_number = full_text[:index].count("\n")
#            print(f"[DEBUG] Match found on line {line_number}")

#            scroll_bar = self.text_area.verticalScrollBar()
#            scroll_bar.setValue(line_number)

#        except Exception as e:
#            print(f"[ERROR] Scroll-only search failed: {e}")


