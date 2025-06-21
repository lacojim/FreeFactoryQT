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
#            print("[DEBUG] Raw output starts:\n", output[:1000])  # Show first 1000 chars
        except Exception as e:
            output = f"Error running ffmpeg:\n{str(e)}"

        title = self.windowTitle().lower()
# If the request is for video codecs only, filter it here
        if args == ["-codecs"] and title.startswith("video codecs"):
            output = self.filter_video_codecs(output)
# If the request is for audio codecs only, filter it here
        elif args == ["-codecs"] and title.startswith("audio codecs"):
            output = self.filter_audio_codecs(output)
# If the request is for video filters only, filter it here
        elif args == ["-filters"] and title.startswith("video filters"):
            output = self.filter_video_filters(output)
# If the request is for audio filters only, filter it here
        elif args == ["-filters"] and title.startswith("audio filters"):
            output = self.filter_audio_filters(output)

        self.text_area.setPlainText(output)

#===Methods for ffmpeg help filtering        
    def filter_video_codecs(self, raw_output: str) -> str:
        lines = raw_output.splitlines()
        filtered = []

        for line in lines:
            if line.strip() == "" or line.startswith("----") or line.startswith("Codecs:"):
                continue
            if len(line) >= 7 and line[3] == 'V':
                filtered.append(line)

        return "\n".join(filtered) if filtered else "No video codecs found."


    def filter_audio_codecs(self, raw_output: str) -> str:
        lines = raw_output.splitlines()
        filtered = []

        for line in lines:
            if line.strip() == "" or line.startswith("----") or line.startswith("Codecs:"):
                continue
            if len(line) >= 7 and line[3] == 'A':
                filtered.append(line)

        return "\n".join(filtered) if filtered else "No audio codecs found."


    def filter_video_filters(self, raw_output: str) -> str:
        lines = raw_output.splitlines()
        filtered = []

        for line in lines:
            if "->" not in line:
                continue
            if "V->V" in line:
                filtered.append(line)

        return "\n".join(filtered) if filtered else "No video filters found."


    def filter_audio_filters(self, raw_output: str) -> str:
        lines = raw_output.splitlines()
        filtered = []

        for line in lines:
            if "->" not in line:
                continue
            if "A->A" in line:
                filtered.append(line)

        return "\n".join(filtered) if filtered else "No audio filters found."

#===End Filtering Methods

        
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


