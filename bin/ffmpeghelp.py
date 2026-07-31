# ffmpeghelp.py
# FFmpeg's "-codecs" output has changed over time and no longer
# reliably lists all implementation names (e.g. libx264, libx265,
# libmp3lame, libopus). Build the "Codecs All" views from the
# authoritative -decoders and -encoders commands instead.

from PyQt6.QtWidgets import QDialog, QVBoxLayout, QPlainTextEdit, QPushButton, QApplication
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QTextOption, QTextCursor, QShortcut, QKeySequence
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
        search_label = QLabel("Search:")
        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Search help text; press Enter for next match")
        search_layout.addWidget(search_label)
        search_layout.addWidget(self.search_input)

        self.clear_search_btn = QPushButton("Clear Search")
        self.clear_search_btn.setAutoDefault(False)
        self.clear_search_btn.clicked.connect(self.clear_search)
        search_layout.addWidget(self.clear_search_btn)

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

        # Make Enter search again regardless of which child widget has focus.
        self.find_next_shortcut = QShortcut(QKeySequence(Qt.Key.Key_Return), self)
        self.find_next_shortcut.setContext(Qt.ShortcutContext.WidgetWithChildrenShortcut)
        self.find_next_shortcut.activated.connect(self.search_text)

        self.find_next_keypad_shortcut = QShortcut(QKeySequence(Qt.Key.Key_Enter), self)
        self.find_next_keypad_shortcut.setContext(Qt.ShortcutContext.WidgetWithChildrenShortcut)
        self.find_next_keypad_shortcut.activated.connect(self.search_text)

        self.clear_search_shortcut = QShortcut(QKeySequence(Qt.Key.Key_Escape), self)
        self.clear_search_shortcut.setContext(Qt.ShortcutContext.WidgetWithChildrenShortcut)
        self.clear_search_shortcut.activated.connect(self.clear_search)

        close_btn = QPushButton("Close")
        close_btn.setAutoDefault(False)
        close_btn.setDefault(False)
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

        def run_help_command(command_args: list[str]) -> str:
            result = subprocess.run(
                [program, "-hide_banner", *command_args],
                capture_output=True,
                text=True,
                check=False,
            )
            return (result.stdout or "") + ("\n" if result.stdout else "") + (result.stderr or "")

        try:
            program = resolve_ffmpeg()
            output = run_help_command(args)
        except Exception as e:
            output = f"Error running ffmpeg:\n{e}"

        title = self.windowTitle().lower()
        if args == ["-codecs"] and title.startswith("video codecs"):
            try:
                decoder_output = run_help_command(["-decoders"])
                encoder_output = run_help_command(["-encoders"])
                output = self.build_codecs_all(
                    decoder_output,
                    encoder_output,
                    media_type="V",
                    media_label="video",
                )
            except Exception as e:
                output = f"Error reading video codecs:\n{e}"
        elif args == ["-codecs"] and title.startswith("audio codecs"):
            try:
                decoder_output = run_help_command(["-decoders"])
                encoder_output = run_help_command(["-encoders"])
                output = self.build_codecs_all(
                    decoder_output,
                    encoder_output,
                    media_type="A",
                    media_label="audio",
                )
            except Exception as e:
                output = f"Error reading audio codecs:\n{e}"
        elif args == ["-filters"] and title.startswith("video filters"):
            output = self.filter_video_filters(output)
        elif args == ["-filters"] and title.startswith("audio filters"):
            output = self.filter_audio_filters(output)

        self.text_area.setPlainText(output)


#===Methods for ffmpeg help filtering
    def build_codecs_all(
        self,
        decoder_output: str,
        encoder_output: str,
        media_type: str,
        media_label: str,
    ) -> str:
        """Build one alphabetized decoder/encoder implementation list.

        Current FFmpeg exposes implementation names authoritatively through
        ``-decoders`` and ``-encoders``. Combining both commands provides a
        complete "Codecs All" view for either video or audio while retaining
        D/E capability information.
        """
        entries: dict[str, dict[str, object]] = {}

        def add_entries(raw_output: str, capability: str) -> None:
            expected_prefix = f" {media_type}"

            for line in raw_output.splitlines():
                if len(line) < 8 or not line.startswith(expected_prefix):
                    continue

                parts = line[7:].strip().split(maxsplit=1)
                if not parts:
                    continue

                name = parts[0]
                description = parts[1] if len(parts) > 1 else ""

                entry = entries.setdefault(
                    name,
                    {"capabilities": set(), "description": description},
                )
                entry["capabilities"].add(capability)

                if not entry["description"] and description:
                    entry["description"] = description

        add_entries(decoder_output, "D")
        add_entries(encoder_output, "E")

        if not entries:
            return f"No {media_label} decoders or encoders found."

        lines = [
            " D/E  NAME                     DESCRIPTION",
            " ---  -----------------------  ----------------------------------------",
        ]

        for name in sorted(entries, key=str.casefold):
            entry = entries[name]
            capabilities = entry["capabilities"]
            marker = "DE" if capabilities == {"D", "E"} else next(iter(capabilities))
            description = entry["description"]
            lines.append(f" {marker:<3}  {name:<23}  {description}")

        return "\n".join(lines)


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

        
    def search_text(self) -> None:
        """Find the next occurrence of the search text, wrapping at the end."""
        query = self.search_input.text().strip()
        if not query:
            return

        found = self.text_area.find(query)

        if not found:
            # Wrap to the beginning and try once more.
            cursor = self.text_area.textCursor()
            cursor.movePosition(QTextCursor.MoveOperation.Start)
            self.text_area.setTextCursor(cursor)
            found = self.text_area.find(query)

        if not found:
            QApplication.beep()
            self.search_input.setFocus()
            self.search_input.selectAll()

    def clear_search(self) -> None:
        """Clear the search text and remove the current match selection."""
        self.search_input.clear()

        cursor = self.text_area.textCursor()
        cursor.clearSelection()
        self.text_area.setTextCursor(cursor)

        self.search_input.setFocus()

