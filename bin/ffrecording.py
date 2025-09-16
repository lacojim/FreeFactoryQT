# ffrecording.py — UI-owned recording manager (independent of background services)
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, List

from PyQt6.QtCore import QObject, QProcess, pyqtSignal


@dataclass
class RecordingSpec:
    input_url: str                 # ":0.0+0,0" | "default" | "/path/to/file" | "rtmp://..." | etc.
    output_path: Path
    framerate: int = 60
    video_size: str = "1920x1080"
    vcodec: str = "h264_nvenc"
    acodec: str = "aac"
    vbps: str = "8M"
    abps: str = "192k"
    extra_vf: str = ""
    extra_args: List[str] = None   # additional args pre-output


class RecordingManager(QObject):
    started = pyqtSignal(Path, list)   # (output_path, argv)
    finished = pyqtSignal(int, str)    # (exit_code, status_text)
    stderr_line = pyqtSignal(str)
    state_changed = pyqtSignal(str)    # "idle"|"starting"|"recording"|"stopping"

    def __init__(self, ffmpeg_path: str = "ffmpeg", parent: Optional[QObject] = None):
        super().__init__(parent)
        self._ffmpeg = ffmpeg_path
        self._proc: Optional[QProcess] = None
        self._state = "idle"

    def is_running(self) -> bool:
        return self._proc is not None

    def _set_state(self, s: str):
        if s != self._state:
            self._state = s
            self.state_changed.emit(s)

    # --- public API ---------------------------------------------------------
    def start(self, spec: RecordingSpec) -> bool:
        if self._proc is not None:
            return False

        spec.output_path.parent.mkdir(parents=True, exist_ok=True)
        args = self._build_cmd(spec)

        p = QProcess(self)
        p.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        p.readyReadStandardError.connect(self._on_stderr)
        p.finished.connect(self._on_finished)
        p.errorOccurred.connect(self._on_error)

        self._set_state("starting")
        p.start(self._ffmpeg, args)
        if not p.waitForStarted(3000):
            self._set_state("idle")
            self.finished.emit(-1, "failed to start ffmpeg")
            return False

        self._proc = p
        self._set_state("recording")
        self.started.emit(spec.output_path, [self._ffmpeg] + args)
        return True

    def stop(self):
        if self._proc is None:
            return
        self._set_state("stopping")
        try:
            self._proc.write(b"q")  # try graceful quit
            self._proc.waitForFinished(1500)
        except Exception:
            pass
        if self._proc is not None and self._proc.state() != QProcess.ProcessState.NotRunning:
            self._proc.kill()
            self._proc.waitForFinished(1500)
        self._cleanup()
        self._set_state("idle")

    # --- internals ----------------------------------------------------------
    def _cleanup(self):
        try:
            if self._proc is not None:
                self._proc.deleteLater()
        except Exception:
            pass
        self._proc = None

    def _on_stderr(self):
        if self._proc is None:
            return
        data = bytes(self._proc.readAllStandardError()).decode("utf-8", errors="replace")
        if data:
            for ln in data.splitlines():
                self.stderr_line.emit(ln)

    def _on_finished(self, code: int, _status):
        self.finished.emit(code, "ok" if code == 0 else f"exit {code}")
        self._cleanup()
        self._set_state("idle")

    def _on_error(self, err):
        self.stderr_line.emit(f"[record] QProcess error: {err}")

    # --- command assembly ----------------------------------------------------
    def _build_cmd(self, s: RecordingSpec) -> List[str]:
        """
        Heuristics:
        - If input looks like an X11 display (starts with ':'), record desktop via x11grab (+ optional Pulse)
        - If it's a local file/HTTP/RTMP, treat as file-like (-re) and remux/encode
        """
        args: List[str] = ["-hide_banner", "-y"]

        src = (s.input_url or "").strip()

        def _is_url(path: str) -> bool:
            return any(path.startswith(p) for p in ("rtmp://", "rtmps://", "http://", "https://", "srt://"))

        if src.startswith(":"):  # X11 desktop
            args += [
                "-thread_queue_size", "512",
                "-f", "x11grab",
                "-framerate", str(s.framerate),
                "-video_size", s.video_size,
                "-i", src or ":0.0+0,0",
                # Optional audio: system default Pulse (easy default for desktop)
                "-thread_queue_size", "512", "-f", "pulse", "-i", "default",
            ]
        elif _is_url(src) or Path(src).exists():
            # File-like / network input
            args += ["-re", "-thread_queue_size", "512", "-i", src]
        else:
            # Fallback: assume desktop
            args += [
                "-thread_queue_size", "512",
                "-f", "x11grab",
                "-framerate", str(s.framerate),
                "-video_size", s.video_size,
                "-i", ":0.0+0,0",
                "-thread_queue_size", "512", "-f", "pulse", "-i", "default",
            ]

        # Codecs
        if src.startswith(":") or not Path(src).exists() or _is_url(src):
            # typical encode path
            args += ["-c:v", s.vcodec, "-b:v", s.vbps, "-preset", "fast", "-pix_fmt", "yuv420p"]
            args += ["-c:a", s.acodec, "-b:a", s.abps]
            if s.extra_vf:
                args += ["-vf", s.extra_vf]
        else:
            # local file exists: keep simple (transcode with given codecs)
            args += ["-c:v", s.vcodec, "-b:v", s.vbps, "-preset", "fast", "-pix_fmt", "yuv420p"]
            args += ["-c:a", s.acodec, "-b:a", s.abps]

        if s.extra_args:
            args += list(s.extra_args)

        args += ["-f", "mp4", str(s.output_path)]
        return args
