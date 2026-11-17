from PyQt6.QtCore import QThread, pyqtSignal, QTimer
import subprocess


class StreamWorker(QThread):
#    finished = pyqtSignal(str)
    error = pyqtSignal(str)
    output = pyqtSignal(str)

    def __init__(self, command: list[str], rtmp_url: str):
        super().__init__()
        self.command = command
        self.rtmp_url = rtmp_url
        self.process = None

    def run(self):
        try:
            self.process = subprocess.Popen(
                self.command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            for line in self.process.stdout:
                self.output.emit(line.strip())
#            self.process.wait()
#            self.finished.emit(self.rtmp_url)
        except Exception as e:
            self.error.emit(f"{self.rtmp_url}: {e}")

    def stop(self):
        if self.process and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()


def stop_all_streams(main_window):
    for worker in list(main_window.active_streams.values()):
        worker.stop()

    main_window.active_streams.clear()
    main_window.active_streams_by_row.clear()

    QTimer.singleShot(
        0,
        lambda: main_window.streamLogOutput.appendPlainText(
            "🔴 All streams stopped."
        )
    )

