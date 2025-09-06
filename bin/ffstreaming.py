from PyQt6.QtCore import QThread, pyqtSignal
import subprocess
import shlex
from pathlib import Path
from PyQt6.QtWidgets import QMessageBox

class StreamWorker(QThread):
    finished = pyqtSignal(str)
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
            self.process.wait()
            self.finished.emit(self.rtmp_url)
        except Exception as e:
            self.error.emit(f"{self.rtmp_url}: {e}")

    def stop(self):
        if self.process and self.process.poll() is None:
            self.process.terminate()
            self.process.wait()

def build_streaming_command(config, core, ui):
    from pathlib import Path
    import shlex
    from PyQt6.QtWidgets import QMessageBox

    factory_name = ui.streamFactorySelect.currentText().strip()
    base_url     = ui.streamRTMPUrl.text().strip()
    stream_key   = ui.streamKey.text().strip()

    factory_location = config.get("FactoryLocation")
    factory_path     = Path(factory_location) / factory_name
    factory          = core.load_factory(factory_path)
    if not factory:
        QMessageBox.warning(ui, "Error", f"Could not load factory: {factory_path}")
        return []

    # Build destination URL
    full_url = base_url.rstrip("/")
    if stream_key:
        full_url = f"{full_url}/{stream_key}"

    cmd = ["ffmpeg", "-hide_banner", "-y"]

    # --- INPUTS ---
    manual_input = (factory.get("MANUALOPTIONSINPUT", "") or "").strip()
    if manual_input and (" -i " in f" {manual_input} " or " -f " in f" {manual_input} "):
        # Verbatim input graph; do NOT inject any extra inputs
        cmd += shlex.split(manual_input)
    else:
        # Assemble inputs from UI with strict adjacency
        v_fmt = ui.ForceFormatInputVideo.currentText().strip() if hasattr(ui, "ForceFormatInputVideo") else ""
        a_fmt = ui.ForceFormatInputAudio.currentText().strip() if hasattr(ui, "ForceFormatInputAudio") else ""
        v_in  = ui.streamInputVideo.text().strip() if hasattr(ui, "streamInputVideo") else ""
        a_in  = ui.streamInputAudio.text().strip() if hasattr(ui, "streamInputAudio") else ""

        if v_in:
            if v_fmt:
                cmd += ["-f", v_fmt]
            cmd += ["-thread_queue_size", "512", "-i", v_in]
        if a_in:
            if a_fmt:
                cmd += ["-f", a_fmt]
            cmd += ["-thread_queue_size", "512", "-i", a_in]

    # --- FLAGS FROM WIDGETS (always) ---
    cmd += core.build_streaming_flags(factory)   # now includes -pix_fmt if set

    # --- MANUAL (post-input/output-stage) ---
    manual_output = (factory.get("MANUALOPTIONSOUTPUT", "") or "").strip()
    if manual_output:
        cmd += shlex.split(manual_output)

    # --- MUXER + URL ---
    force_format = (factory.get("FORCEFORMAT", "") or "").strip()
    if force_format:
        cmd += ["-f", force_format]
    cmd.append(full_url)

    print("DEBUG Streaming CMD:", cmd)
    return cmd




def start_all_streams(main_window):
    for row in range(main_window.streamTable.rowCount()):
        factory_name = main_window.streamTable.item(row, 0).text()
        stream_key = main_window.streamTable.item(row, 1).text()
        rtmp_url = main_window.streamTable.item(row, 2).text()

        # Simulate selecting the row’s values into the GUI
        main_window.streamFactorySelect.setCurrentText(factory_name)
        main_window.streamKey.setText(stream_key)
        main_window.streamRTMPUrl.setText(rtmp_url)

        cmd = build_streaming_command(config, core, ui)
        if not cmd:
            continue

        worker = StreamWorker(cmd, rtmp_url)
        worker.output.connect(main_window.streamLogOutput.appendPlainText)
        worker.finished.connect(lambda url=rtmp_url: handle_stream_stopped(main_window, url))
        main_window.active_streams[full_output_url] = worker
        print(f"[DEBUG] Stream started and stored under key: {rtmp_url}")
        worker.start()
        main_window.streamLogOutput.appendPlainText(f"🟢 Started stream: {factory_name}")


def stop_all_streams(main_window):
    for worker in list(main_window.active_streams.values()):
        worker.stop()
    main_window.active_streams.clear()
    main_window.streamLogOutput.appendPlainText("🔴 All streams stopped.")
    
def stop_single_stream(main_window, stream_data):
    """Stops a single active stream by RTMP URL key."""
    rtmp_url = stream_data.get("rtmp_url", "")
    if rtmp_url in main_window.active_streams:
        worker = main_window.active_streams[rtmp_url]
        worker.stop()
        del main_window.active_streams[rtmp_url]
        main_window.streamLogOutput.appendPlainText(f"🔴 Stopped stream: {rtmp_url}")
    else:
        main_window.streamLogOutput.appendPlainText(f"⚠️ No active stream for: {rtmp_url}")


def handle_stream_stopped(main_window, url):
    main_window.streamLogOutput.appendPlainText(f"🔴 Stream ended: {url}")
    
def start_single_stream(main_window, stream_data=None):

    if stream_data:
        # Use passed-in stream values
        factory_name = stream_data["factory_name"]
        rtmp_url = stream_data["rtmp_url"]
        stream_key = stream_data["stream_key"]
        ...
        main_window.streamFactorySelect.setCurrentText(factory_name)
        main_window.streamRTMPUrl.setText(rtmp_url)
        main_window.streamKey.setText(stream_key)

    
    cmd = build_streaming_command(main_window.config, main_window.core, main_window)
    if not cmd:
        return

    full_output_url = cmd[-1]
    main_window.streamLogOutput.clear()

    worker = StreamWorker(cmd, full_output_url)
    worker.output.connect(main_window.streamLogOutput.appendPlainText)
    worker.finished.connect(lambda url=full_output_url: handle_stream_stopped(main_window, url))

    # Unified management of streaming workers
    main_window.active_streams[rtmp_url] = worker
    worker.start()

    main_window.streamLogOutput.appendPlainText(f"🟢 Started stream: {full_output_url}")
