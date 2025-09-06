# ffmpeghelp.py

from PyQt6.QtWidgets import QDialog, QVBoxLayout, QPlainTextEdit, QPushButton
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QTextOption
from PyQt6.QtWidgets import QLineEdit, QHBoxLayout, QLabel
from PyQt6.QtGui import QFont
import subprocess

import os, shutil
from pathlib import Path

class FFmpegHelpDialog(QDialog):
    def __init__(self, title: str, ffmpeg_args: list[str], parent=None, ffmpeg_path: str | None = None):
        super().__init__(parent)
        self._ffmpeg_path = ffmpeg_path  # new: remember which ffmpeg to use

        self.setWindowTitle(title)
        self.setMinimumSize(800, 600)

        layout = QVBoxLayout(self)

        # Search bar
        search_layout = QHBoxLayout()
        search_label = QLabel("Find:")
        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Search (disabled on this system)")
        self.search_input.returnPressed.connect(self.search_text)
        search_layout.addWidget(search_label)
        search_layout.addWidget(self.search_input)
        layout.addLayout(search_layout)

        # Output area
        self.text_area = QPlainTextEdit()
        self.text_area.setReadOnly(True)
        self.text_area.setWordWrapMode(QTextOption.WrapMode.NoWrap)

        font = QFont("monospace")
        font.setStyleHint(QFont.StyleHint.TypeWriter)
        font.setPointSize(10)
        self.text_area.setFont(font)

        layout.addWidget(self.text_area)

        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.close)
        layout.addWidget(close_btn, alignment=Qt.AlignmentFlag.AlignRight)

        # run initial command
        self.run_ffmpeg(ffmpeg_args)


    def run_ffmpeg(self, args: list[str]) -> None:
        """Run ffmpeg with the selected path (or PATH fallback)."""
        import os, shutil, subprocess

        def resolve_ffmpeg():
            p = (self._ffmpeg_path or "").strip()
            if p:
                p = p.rstrip("/")
                if os.path.isdir(p):
                    p = os.path.join(p, "ffmpeg")
                return shutil.which(p) or p
            return shutil.which("ffmpeg") or "ffmpeg"

        try:
            program = resolve_ffmpeg()
            result = subprocess.run(
                [program, "-hide_banner", *args],
                capture_output=True,
                text=True,
                check=False,
            )
            output = (result.stdout or "") + ("\n" if result.stdout else "") + (result.stderr or "")
        except Exception as e:
            output = f"Error running ffmpeg:\n{e}"

        title = self.windowTitle().lower()
        if args == ["-codecs"] and title.startswith("video codecs"):
            output = self.filter_video_codecs(output)
        elif args == ["-codecs"] and title.startswith("audio codecs"):
            output = self.filter_audio_codecs(output)
        elif args == ["-filters"] and title.startswith("video filters"):
            output = self.filter_video_filters(output)
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

