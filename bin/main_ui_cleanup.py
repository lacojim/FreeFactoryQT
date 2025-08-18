# main.py (Phase 1 Refactor: Grouping + Cleanup)
# Functional logic extracted and converted from ProgramFrontEnd.tcl
#############################################################################
#               This code is licensed under the GPLv3
#    The following terms apply to all files associated with the software
#    unless explicitly disclaimed in individual files or parts of files.
#
#                           Free Factory
#
#                          Copyright 2025
#                               by
#                     Jim Hines and Karl Swisher
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
# ============================
#         Imports
# ============================
import sys
import os
import shlex
import shutil
import subprocess

from pathlib import Path
from datetime import datetime

from PyQt6.QtCore import Qt, QThread, QTimer
from PyQt6.QtGui import QPixmap
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QListWidgetItem, QMessageBox,
    QTableWidgetItem, QDialog, QVBoxLayout, QPlainTextEdit,
    QPushButton, QFileDialog, QHeaderView, QLabel, QComboBox,
    QLineEdit, QMenu, QCheckBox
)
from PyQt6.uic import loadUi

from config_manager import ConfigManager
from core import FFmpegWorker, FreeFactoryCore, FFmpegWorkerZone
from droptextedit import DropTextEdit
from ffmpeghelp import FFmpegHelpDialog
from ffstreaming import (
    StreamWorker, build_streaming_command,
    start_single_stream, stop_single_stream,
    start_all_streams, stop_all_streams,
    handle_stream_stopped
)
from ffnotifyservice import (
    connect_notify_service_controls,
    update_notify_service_mode_display,
    show_notify_service_menu
)
from importexport import ExportFactoryDialog, export_factory_logic, backup_factories_zip
#from importexport import backup_factories_zip

STATUS_COL = 5


# ============================
#      Dialog Definitions
# ============================
class LicenseDialog(QDialog):
    def __init__(self, license_text, parent=None):
        super().__init__(parent)
        self.setWindowTitle("FreeFactory License")
        self.setMinimumSize(600, 400)
        layout = QVBoxLayout()

        logo_label = QLabel()
        logo_path = Path(__file__).parent.parent / "Pics" / "gplv3-88x31.png"
        if logo_path.exists():
            pixmap = QPixmap(str(logo_path))
            logo_label.setPixmap(pixmap)
            logo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            layout.addWidget(logo_label)

        text_edit = QPlainTextEdit()
        text_edit.setReadOnly(True)
        text_edit.setPlainText(license_text)
        layout.addWidget(text_edit)

        close_btn = QPushButton("Close", self)
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn)

        self.setLayout(layout)


class AboutDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("About FreeFactory")
        self.setMinimumSize(335, 200)
        layout = QVBoxLayout()

        logo_label = QLabel()
        logo_path = Path(__file__).parent.parent / "Pics" / "FreeFactoryProgramLogo.png"
        if logo_path.exists():
            pixmap = QPixmap(str(logo_path)).scaled(
                128, 128,
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation
            )
            logo_label.setPixmap(pixmap)
            logo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            layout.addWidget(logo_label)

        about_text = ("""
        <b>FreeFactory</b><br>
        Version 1.1<br>
        An open-source professional media conversion app.<br><br>
        © 2013–2025 Jim Hines and Karl Swisher<br>
        Licensed under <a href='https://www.gnu.org/licenses/gpl-3.0.html'>GPLv3</a><br>
        <a href='https://github.com/lacojim/FreeFactoryQT'>github.com/lacojim/FreeFactoryQT</a>
        """)
        text_label = QLabel(about_text)
        text_label.setOpenExternalLinks(True)
        text_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(text_label)

        close_btn = QPushButton("Close", self)
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn, alignment=Qt.AlignmentFlag.AlignCenter)

        self.setLayout(layout)


# ============================
#     Main Application Stub
# ============================
class FreeFactoryApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.config = ConfigManager()
        self.core = FreeFactoryCore(self.config)
        self.factory_dirty = False
        self.active_threads = []
        self.queue_paused = False
        self.active_streams = {}

        ui_path = Path(__file__).parent / "FreeFactory-tabs.ui"
        loadUi(ui_path, self)

        self.setup_ui()
        self.populate_factory_list()

        # Populate DefaultFactoryGlobal combo box with available factories
        factory_dir = self.config.get("FactoryLocation") or "/opt/FreeFactory/Factories"
        factory_paths = sorted(Path(factory_dir).glob("*"))
        factory_names = [f.name for f in factory_paths if f.is_file()] # Changed f.stem to f.name to fix factory files with a dot inside the name.
        self.DefaultFactoryGlobal.clear()
        self.DefaultFactoryGlobal.addItems(factory_names)
        self.DefaultFactoryGlobal.setCurrentText(self.config.get("DefaultFactory", "default"))

        # Set Global Settings tab with config values
        self.CompanyNameGlobal.setText(self.config.get("CompanyNameGlobal"))
#        self.MaxConcurrentJobsGlobal.setText(self.config.get("MaxConcurrentJobs", "1"))
        self.CpuMaxConcurrentJobsGlobal.setValue(int(self.config.get("MaxConcurrentJobsCPU", "1") or 1))
        self.GpuMaxConcurrentJobsGlobal.setValue(int(self.config.get("MaxConcurrentJobsGPU", "2") or 2))

        self.AppleDelaySecondsGlobal.setText(self.config.get("AppleDelaySeconds"))
        self.PathtoFFmpegGlobal.setText(self.config.get("PathtoFFmpegGlobal"))
        self.PathtoFactoriesGlobal.setText(self.config.get("FactoryLocation"))
        self.DefaultFactoryGlobal.setCurrentText(self.config.get("DefaultFactory"))

        # Auto-select and load the default factory
        default_factory = self.config.get("DefaultFactory")
        if default_factory:
            matching_items = self.listFactoryFiles.findItems(default_factory, Qt.MatchFlag.MatchExactly)
            if matching_items:
                self.listFactoryFiles.setCurrentItem(matching_items[0])
                self.load_selected_factory(matching_items[0]) 



    # ============================
    #       UI Setup Logic
    # ============================
    def setup_ui(self):
        self.SaveFFConfigGlobal.clicked.connect(self.save_global_config)
        self.ViewLicense.clicked.connect(self.show_license)
        self.AboutFreeFactory.clicked.connect(self.show_about)
        self.toolButton_notifyDir.clicked.connect(self.select_notify_directory)
        self.toolButton_outputDir.clicked.connect(self.select_output_directory)
        self.PreviewCommand.clicked.connect(self.on_generate_command)
        
        
        
        # FreeFactory Factory Management Buttons
        self.SaveFactory.clicked.connect(self.save_current_factory)
        self.DeleteFactory.clicked.connect(self.delete_current_factory)
        self.NewFactory.clicked.connect(self.new_factory)
        self.ImportFactory.clicked.connect(self.import_factory)
        self.ExportFactory.clicked.connect(self.export_factory)
        self.BackupFactories.clicked.connect(self.backup_factories)
        
        # Factory List
        self.listFactoryFiles.itemClicked.connect(self.load_selected_factory)
        
        # File Queue Buttons
        self.startQueueButton.clicked.connect(self.start_conversion_queue)
        self.pauseQueueButton.clicked.connect(self.pause_or_resume_queue)
        self.clearQueueButton.clicked.connect(self.clear_conversion_queue)
        self.removeFromQueueButton.clicked.connect(self.remove_selected_from_queue)
        self.conversionQueueTable.setColumnWidth(0, 300)  # Input file
        self.conversionQueueTable.setColumnWidth(1, 300)  # Output file
        self.conversionQueueTable.setColumnWidth(2, 120)  # Status column
        self.conversionQueueTable.horizontalHeader().setStretchLastSection(True)
        
        # Streaming Buttons
        self.StartAllStreams.clicked.connect(self.start_all_streams)
        self.StopAllStreams.clicked.connect(self.stop_all_streams)
        self.StartStream.clicked.connect(self.start_selected_stream)
        self.StopStream.clicked.connect(self.stop_selected_stream)
        self.AddNewStream.clicked.connect(self.add_stream_to_table)
        self.RemoveStream.clicked.connect(self.remove_selected_stream)
        
        # Populate Streaming Factory list
        factory_dir = self.config.get("FactoryLocation") or "/opt/FreeFactory/Factories"
        factory_files = sorted(Path(factory_dir).glob("*"))
        
        self.streamTable.setColumnWidth(0, 250)  # Input file
        self.streamTable.setColumnWidth(1, 250)  # Output file
        self.streamTable.setColumnWidth(2, 200)  # Input Audio column
        self.streamTable.setColumnWidth(3, 100)
        self.streamTable.setColumnWidth(4, 100)
        self.streamTable.horizontalHeader().setStretchLastSection(True)

        # Streaming Factories List
        factory_files = sorted(Path(factory_dir).glob("*"))
        factory_names = [f.name for f in factory_files if f.is_file()]
        self.streamFactorySelect.clear()
        self.streamFactorySelect.addItems(factory_names)
        
    # ============================
    #     Help Buttons
    # ============================
        self.helpVCodecsAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Video Codecs", ["-codecs"])
        )
        
        self.helpVCodecsFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Encoder Help: {self.helpVCodecsFilter.text()}",
                ["-h", f"encoder={self.helpVCodecsFilter.text()}"]
            )
        )

        self.helpACodecsAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Audio Codecs", ["-codecs"])
        )
        
        self.helpACodecsFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Encoder Help: {self.helpACodecsFilter.text()}",
                ["-h", f"encoder={self.helpACodecsFilter.text()}"]
            )
        )

        self.helpMuxersAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Muxers", ["-muxers"])
        )
        
        self.helpMuxersFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Muxer Help: {self.helpMuxersFilter.text()}",
                ["-h", f"muxer={self.helpMuxersFilter.text()}"]
            )
        )

        self.helpVFiltersAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Video Filters", ["-filters"])
        )

        self.helpVFiltersFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Video Filter Help: {self.helpVFiltersFilter.text()}",
                ["-h", f"filter={self.helpVFiltersFilter.text()}"]
            )
        )

        self.helpAFiltersAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Audio Filters", ["-filters"])
        )

        self.helpAFiltersFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Audio Filter Help: {self.helpAFiltersFilter.text()}",
                ["-h", f"filter={self.helpAFiltersFilter.text()}"]
            )
        )
            
        self.helpBSFAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Bitstream Filters", ["-bsfs"])
        )

        self.helpBSFFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Bitstream Filter Help: {self.helpBSFFilter.text()}",
                ["-h", f"bsf={self.helpBSFFilter.text()}"]
            )
        )            

        self.helpPixFormatsAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Pixel Formats", ["-pix_fmts"])
        )

        self.helpDevicesAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Devices", ["-devices"])
        )

        self.helpAllHelp.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Full FFmpeg Help", ["-h", "full"])
        )

        # FreeFactory DropZones 
        self.dropZone.filesDropped.connect(self.handle_dropped_files)
        self.queueDropZone.filesDropped.connect(self.handle_dropped_files_to_queue)
        
        # FreeFactory Service Buttons
        update_notify_service_mode_display(self)
        connect_notify_service_controls(self)
        self.clearNotifyStatusButton.clicked.connect(lambda: self.listNotifyServiceStatus.clear())

        # FreeFactory Clear Preview and Dropzone Buttons        
        self.clearPreviewButton.clicked.connect(lambda: self.PreviewCommandLine.clear())
        self.clearDropZoneButton.clicked.connect(lambda: self.dropZone.clear())

        
        

    # ============================
    #     File Queue Handlers
    # ============================
    def start_conversion_queue(self):
        self.current_queue_index = 0
        self.run_next_in_queue()

    def pause_or_resume_queue(self):
        self.queue_paused = not self.queue_paused
        if self.queue_paused:
            self.pauseQueueButton.setText("Resume Queue")
        else:
            self.pauseQueueButton.setText("Pause Queue")
            self.run_next_in_queue()

    def run_next_in_queue(self):
        if self.queue_paused:
            return
        if self.current_queue_index >= self.conversionQueueTable.rowCount():
            self.conversionProgressBar.setValue(100)
            return

        input_path = self.conversionQueueTable.item(self.current_queue_index, 0).text()
        output_path = self.conversionQueueTable.item(self.current_queue_index, 1).text()
        factory_name = self.FactoryFilename.text().strip()
        factory_path = Path(self.config.get("FactoryLocation")) / factory_name
        factory_data = self.core.load_factory(factory_path)
        cmd = self.core.build_ffmpeg_command(input_path, factory_data)

        self.conversionQueueTable.setItem(self.current_queue_index, 2, QTableWidgetItem("Processing..."))

        try:
            if not cmd or not isinstance(cmd, (list, tuple)):
                raise ValueError("Invalid command passed to FFmpegWorker.")

            self.worker = FFmpegWorker(cmd)
            self.worker.result.connect(self.handle_worker_result)
            self.worker.finished.connect(self.worker.deleteLater)
            self.worker.start()

        except Exception as e:
            self.dropZone.appendPlainText(f"⚠️ Exception preparing command: {e}")
            self.worker = None

    def handle_worker_result(self, returncode, stdout, stderr):
        status = "✅ Done" if returncode == 0 else f"❌ Failed"
        if returncode != 0:
            print(f"[FFmpeg stderr]: {stderr}")

        self.conversionQueueTable.setItem(self.current_queue_index, 2, QTableWidgetItem(status))
        progress = int((self.current_queue_index + 1) / self.conversionQueueTable.rowCount() * 100)
        self.conversionProgressBar.setValue(progress)
        self.current_queue_index += 1
        QTimer.singleShot(200, self.run_next_in_queue)

    def clear_conversion_queue(self):
        self.conversionQueueTable.setRowCount(0)
        self.conversionProgressBar.setValue(0)

    def remove_selected_from_queue(self):
        selected_rows = set()
        for item in self.conversionQueueTable.selectedItems():
            selected_rows.add(item.row())
        for row in sorted(selected_rows, reverse=True):
            self.conversionQueueTable.removeRow(row)


    # ============================
    #     Drag and Drop Logic
    # ============================
    def handle_dropped_files(self, files):
        if not self.listFactoryFiles.currentItem():
            QMessageBox.warning(self, "No Factory Selected", "Please select a factory before dropping files.")
            return

        factory_name = self.FactoryFilename.text().strip()
        available_factories = [Path(f).stem for f in self.core.factory_files]

        if not factory_name or factory_name not in available_factories:
            QMessageBox.warning(self, "Invalid Factory", "Selected factory configuration is invalid.")
            return

        factory_path = Path(self.config.get("FactoryLocation")) / factory_name
        factory_data = self.core.load_factory(factory_path)

        for file_path in files:
            self.dropZone.appendPlainText(f"🔄 Processing: {file_path}")
            try:
                cmd = self.core.build_ffmpeg_command(file_path, factory_data)
                self.dropZone.appendPlainText(f"⚙️ Running command:{' '.join(cmd)}")

                thread = QThread()
                worker = FFmpegWorkerZone(cmd)
                worker.moveToThread(thread)

                worker.finished.connect(lambda msg, fp=file_path: self.dropZone.appendPlainText(f"{msg}✔️ File: {fp}"))
                worker.error.connect(lambda msg, fp=file_path: self.dropZone.appendPlainText(f"{msg}❌ File: {fp}"))

                thread.started.connect(worker.run)
                worker.finished.connect(thread.quit)
                worker.error.connect(thread.quit)
                worker.finished.connect(worker.deleteLater)
                worker.error.connect(worker.deleteLater)
                thread.finished.connect(thread.deleteLater)

                thread.start()
                self.active_threads.append((thread, worker))

                def cleanup():
                    self.active_threads = [(t, w) for (t, w) in self.active_threads if t != thread]

                thread.finished.connect(cleanup)

            except Exception as e:
                self.dropZone.appendPlainText(f"⚠️ Exception preparing command: {str(e)}")

    def handle_dropped_files_to_queue(self, files):
        if not self.listFactoryFiles.currentItem():
            QMessageBox.warning(self, "No Factory Selected", "Please select a factory before dropping files.")
            return

        factory_name = self.FactoryFilename.text().strip()
        available_factories = [Path(f).stem for f in self.core.factory_files]

        if not factory_name or factory_name not in available_factories:
            QMessageBox.warning(self, "Invalid Factory", "Selected factory configuration is invalid.")
            return

        factory_path = Path(self.config.get("FactoryLocation")) / factory_name
        factory_data = self.core.load_factory(factory_path)

        for input_path in files:
            cmd = self.core.build_ffmpeg_command(input_path, factory_data)
            output_path = cmd[-1]
            self.add_file_to_queue(input_path, output_path)


    def add_file_to_queue(self, input_path, output_path):
        row_position = self.conversionQueueTable.rowCount()
        self.conversionQueueTable.insertRow(row_position)
        self.conversionQueueTable.setItem(row_position, 0, QTableWidgetItem(str(input_path)))
        self.conversionQueueTable.setItem(row_position, 1, QTableWidgetItem(str(output_path)))
        self.conversionQueueTable.setItem(row_position, 2, QTableWidgetItem("Queued"))


    # ============================
    #     Help Dialog
    # ============================

    def open_ffmpeg_help_dialog(self, title, args):
        # Keep a reference so it doesn't get garbage collected
        self._ffmpeg_help_dialog = FFmpegHelpDialog(title, args, self)
        self._ffmpeg_help_dialog.show()

    # ============================
    #     Streaming Controls
    # ============================
    def start_all_streams(self):
        for row in range(self.streamTable.rowCount()):
            item = self.streamTable.item(row, 0)
            if not item:
                continue

            stream_data = item.data(Qt.ItemDataRole.UserRole)
            if not stream_data:
                continue

            start_single_stream(self, stream_data=stream_data)
            
    def start_selected_stream(self):
        row = self.streamTable.currentRow()
        if row < 0:
            QMessageBox.warning(self, "No Selection", "Please select a stream row.")
            return
        self.start_stream_for_row(row)




    def start_stream_for_row(self, row: int):
        # Status → Starting...
        self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Starting..."))

        item0 = self.streamTable.item(row, 0)
        stream_data = item0.data(Qt.ItemDataRole.UserRole) if item0 else None
        if not stream_data:
            self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Error: No data"))
            return

        # Mirror row → UI if your builder reads from UI fields (optional but harmless)
        if hasattr(self, "streamFactorySelect"):
            self.streamFactorySelect.setCurrentText(stream_data.get("factory_name", ""))
        if hasattr(self, "streamRTMPUrl"):
            self.streamRTMPUrl.setText(stream_data.get("rtmp_url", ""))
        if hasattr(self, "streamKey"):
            self.streamKey.setText(stream_data.get("stream_key", ""))

        # Build & launch
        cmd = build_streaming_command(self.config, self.core, self)
        if not cmd:
            self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Error: Bad command"))
            return

        full_output_url = cmd[-1]
        worker = StreamWorker(cmd, full_output_url)
        worker.output.connect(self.streamLogOutput.appendPlainText)
        worker.finished.connect(lambda: self._on_stream_finished(row, full_output_url, False))
        worker.error.connect(lambda m: self._on_stream_error(row, full_output_url, m))

        if not hasattr(self, "active_streams"):
            self.active_streams = {}
        self.active_streams[full_output_url] = worker

        worker.start()
        self.streamLogOutput.appendPlainText(f"🟢 Started stream: {full_output_url}")

    def _on_stream_finished(self, row: int, url: str, had_error: bool):
        # Cleanup worker dict
        if hasattr(self, "active_streams") and url in self.active_streams:
            del self.active_streams[url]
        # Update status and re-enable Start if a row is selected
        self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Error" if had_error else "Stopped"))
        self.StartStream.setEnabled(self.streamTable.currentRow() >= 0)



    def _maybe_mark_live(self, row: int, line: str):
        if "frame=" in line or "bitrate=" in line or "Connected" in line:
            # Only flip if still in Starting…
            item = self.streamTable.item(row, STATUS_COL)
            if item and item.text().startswith("Starting"):
                self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Live"))


    def _on_stream_finished(self, row: int, url: str, had_error: bool):
        # Drop the worker reference keyed by FULL destination URL
        if hasattr(self, "active_streams") and url in self.active_streams:
            del self.active_streams[url]

        # Update table status
        self.streamTable.setItem(row, STATUS_COL,
                                QTableWidgetItem("Error" if had_error else "Stopped"))

        # Re-enable Start if a row is selected
        self.StartStream.setEnabled(self.streamTable.currentRow() >= 0)


    def _on_stream_error(self, row: int, url: str, msg: str):
        # Log the error and funnel to the same finisher with had_error=True
        self.streamLogOutput.appendPlainText(f"🔴 {msg}")
        self._on_stream_finished(row, url, had_error=True)




    def stop_all_streams(self):
        stop_all_streams(self)

    def stop_selected_stream(self):
        row = self.streamTable.currentRow()
        if row < 0:
            return

        # Build full URL key just like start did
        base = self.streamRTMPUrl.text().strip()
        key  = self.streamKey.text().strip()
        url  = f"{base.rstrip('/')}/{key}" if key else base

        worker = self.active_streams.get(url) if hasattr(self, "active_streams") else None
        if not worker:
            self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Stopped"))
            self.StartStream.setEnabled(self.streamTable.currentRow() >= 0)
            return

        worker.stop()
        # _on_stream_finished will run via worker.finished / worker.error

 
    def remove_selected_stream(self):
        selected_row = self.streamTable.currentRow()
        if selected_row < 0:
            QMessageBox.warning(self, "No Selection", "Please select a stream to remove.")
            return

        item = self.streamTable.item(selected_row, 0)
        if not item:
            return

        stream_data = item.data(Qt.ItemDataRole.UserRole)
        if stream_data:
            rtmp_url = stream_data.get("rtmp_url")
            if rtmp_url and rtmp_url in self.active_streams:
                self.active_streams[rtmp_url].stop()
                del self.active_streams[rtmp_url]
                self.streamLogOutput.appendPlainText(f"🔴 Stopped and removed: {rtmp_url}")

        self.streamTable.removeRow(selected_row)

    def add_stream_to_table(self):
        row = self.streamTable.rowCount()
        self.streamTable.insertRow(row)

        # Gather current UI values
        factory_name = self.streamFactorySelect.currentText().strip() if hasattr(self, "streamFactorySelect") else ""
        v_in   = self.streamInputVideo.text().strip()   if hasattr(self, "streamInputVideo") else ""
        a_in   = self.streamInputAudio.text().strip()   if hasattr(self, "streamInputAudio") else ""
        base   = self.streamRTMPUrl.text().strip()      if hasattr(self, "streamRTMPUrl")   else ""
        key    = self.streamKey.text().strip()          if hasattr(self, "streamKey")       else ""
        mux    = ""  # optional: summary; leave blank or fill from factory if you like

        # Build the full destination URL (with auth if streamAuthMode == 'url')
        full_url = base.rstrip("/")
        if key:
            full_url = f"{full_url}/{key}"

        if hasattr(self, "streamAuthMode") and self.streamAuthMode.currentText().strip() == "url":
            user = self.streamUsername.text().strip() if hasattr(self, "streamUsername") else ""
            pwd  = self.streamPassword.text().strip() if hasattr(self, "streamPassword") else ""
            if user and pwd and "@" not in full_url.split("://", 1)[-1]:
                scheme, rest = full_url.split("://", 1) if "://" in full_url else ("rtmp", full_url)
                full_url = f"{scheme}://{user}:{pwd}@{rest}"

        # Fill visible columns
        self.streamTable.setItem(row, 0, QTableWidgetItem(factory_name or "<factory>"))
        self.streamTable.setItem(row, 1, QTableWidgetItem(v_in))
        self.streamTable.setItem(row, 2, QTableWidgetItem(a_in))
        self.streamTable.setItem(row, 3, QTableWidgetItem(base))     # base URL (no key), useful to read back
        self.streamTable.setItem(row, 4, QTableWidgetItem(mux))      # summary (optional)
        self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Idle"))

        # Stash per-row metadata (this is what Start will read)
        stream_data = {
            "factory_name": factory_name,
            "video_input": v_in,
            "audio_input": a_in,
            "rtmp_url": base,           # base without key
            "stream_key": key,
            "output_url": full_url,     # full destination (with key/auth if any)
        }
        item0 = self.streamTable.item(row, 0)
        item0.setData(Qt.ItemDataRole.UserRole, stream_data)

        # Select the new row so Start is enabled
        self.streamTable.setCurrentCell(row, 0)

    def handle_stream_stopped(self, message):
        self.streamLogOutput.appendPlainText(f"🔴 Stream ended: {message}")


    # ============================
    #     Factory Management
    # ============================
    def save_current_factory(self):
        filename = self.FactoryFilename.text().strip()
        notify_dir = self.NotifyDirectory.text().strip()
        output_dir = self.OutputDirectory.text().strip()
        # Ensure trailing slash
        if notify_dir and not notify_dir.endswith("/"):
            notify_dir += "/"
        if output_dir and not output_dir.endswith("/"):
            output_dir += "/"
            
        if not filename:
            QMessageBox.warning(self, "Missing Filename", "Please provide a factory filename.")
            return

        filepath = self.core.factory_dir / filename

        lines = [
            f"FACTORYDESCRIPTION={self.FactoryDescription.text().strip()}",
            f"NOTIFYDIRECTORY={notify_dir}",
            f"OUTPUTDIRECTORY={output_dir}",
            "OUTPUTFILESUFFIX=",                                            # <— hardcoded empty line since this was removed from UI
            f"FFMXPROGRAM=ffmpeg",                                          # Depreciated for Removal
            f"RUNFROM=usr",                                                 # Depreciated for Removal
            f"FTPPROGRAM=",                                                 # Depreciated for Removal
            f"FTPURL=",                                                     # Depreciated for Removal
            f"FTPUSERNAME=",                                                # Depreciated for Removal
            f"FTPPASSWORD=",                                                # Depreciated for Removal
            f"FTPREMOTEPATH=",                                              # Depreciated for Removal
            f"FTPTRANSFERTYPE=bin",                                         # Depreciated for Removal
            f"FTPDELETEAFTER=Yes",                                          # Depreciated for Removal
            f"VIDEOCODECS={self.VideoCodec.currentText().strip()}",
            f"VIDEOWRAPPER={self.VideoWrapper.currentText().strip()}",
            f"VIDEOFRAMERATE={self.VideoFrameRate.currentText().strip()}",
            f"VIDEOSIZE={self.VideoSize.currentText().strip()}",
            f"VIDEOTARGET={self.VideoTarget.currentText().strip()}",
            f"VIDEOTAGS={self.VideoTags.currentText().strip()}",
            f"VIDEOFILTERS={self.videoFiltersCombo.currentText().strip()}",
            f"VIDEOPIXFORMAT={self.VideoPixFormat.currentText().strip()}",
            f"THREADS={self.Threads.currentText().strip()}",
            f"ASPECT={self.VideoAspect.currentText().strip()}",
            f"VIDEOBITRATE={self.VideoBitrate.currentText().strip()}",
            f"VIDEOPROFILE={self.VideoProfile.currentText().strip()}",
            f"VIDEOPROFILELEVEL={self.VideoProfileLevel.currentText().strip()}",
            f"VIDEOPRESET={self.VideoPreset.currentText().strip()}",
            f"VIDEOSTREAMID={self.VideoStreamID.text().strip()}",
            f"GROUPPICSIZE={self.VideoGroupPicSize.text().strip()}",
            f"BFRAMES={self.VideoBFrames.text().strip()}",
            f"FRAMESTRATEGY={self.FrameStrategy.currentText().strip()}",
            f"FORCEFORMAT={self.ForceFormat.currentText().strip()}",
            f"ENCODELENGTH={self.EncodeLength.text().strip()}",
            f"STARTTIMEOFFSET={self.VideoStartTimeOffset.text().strip()}",
            f"SUBTITLECODECS={self.SubtitleCodecs.currentText().strip()}",
            f"AUDIOCODECS={self.AudioCodec.currentText().strip()}",
            f"AUDIOBITRATE={self.AudioBitrate.currentText().strip()}",
            f"AUDIOSAMPLERATE={self.AudioSampleRate.currentText().strip()}",
            f"AUDIOFILEEXTENSION={self.AudioExtension.currentText().strip()}",
            f"AUDIOTAG={self.AudioTag.text().strip() if hasattr(self, 'AudioTag') else ''}",
            f"AUDIOFILTERS={self.audioFiltersCombo.currentText().strip()}",
            f"AUDIOCHANNELS={self.AudioChannels.currentText().strip()}",
            f"AUDIOSTREAMID={self.AudioStreamID.text().strip()}",
            f"MANUALOPTIONS={self.ManualOptions.text().strip()}",
            f"MANUALOPTIONSINPUT={self.ManualOptionsInput.text().strip()}",
            f"DELETESOURCE={'Yes' if self.DeleteSource.isChecked() else 'No'}",
            f"DELETECONVERSIONLOGS={'Yes' if self.DeleteConversionLogs.isChecked() else 'No'}",
            f"ENABLEFACTORY={'Yes' if self.EnableFactory.isChecked() else 'No'}",
            f"FREEFACTORYACTION={'Encode' if self.ActionEncode.isChecked() else 'Copy'}",
            f"ENABLEFACTORYLINKING={'Yes' if self.EnableFactoryLinking.isChecked() else 'No'}",   # Depreciated for Removal
            f"FACTORYLINKS=",                                                                       # Depreciated for Removal
            f"FACTORYENABLEEMAIL=Yes",                                                          # Depreciated for Removal
            f"FACTORYEMAILNAME=",                                                             # Depreciated for Removal
            f"FACTORYEMAILADDRESS=",                                                             # Depreciated for Removal
            f"FACTORYEMAILMESSAGESTART=",                                                           # Depreciated for Removal
            f"FACTORYEMAILMESSAGEEND=",
            
#===========streaming widgets             
            f"FORCEFORMATINPUTVIDEO={self.ForceFormatInputVideo.currentText().strip()}",
            f"FORCEFORMATINPUTAUDIO={self.ForceFormatInputAudio.currentText().strip()}",
            f"STREAMINPUTVIDEO={self.streamInputVideo.text().strip()}",
            f"STREAMINPUTAUDIO={self.streamInputAudio.text().strip()}",
            f"STREAMRTMPURL={self.streamRTMPUrl.text().strip()}",
            f"STREAMKEY={self.streamKey.text().strip()}",
            f"STREAMINGFACTORYNAME={self.StreamingFactoryName.text().strip()}",
            f"INCLUDETQS={'True' if self.checkIncludeTQS.isChecked() else 'False'}",
            f"TQSSIZE={self.tqsSizeCombo.currentText().strip()}",
            f"LOWLATENCYINPUT={'True' if self.checkLowLatencyInput.isChecked() else 'False'}",
            f"AUTOMAPAV={'True' if self.checkMapAVInputs.isChecked() else 'False'}"

        ]

        filepath.write_text("\n".join(lines) + "\n")

        #print(f"Saved to: {filepath}")
        #print("Calling populate_factory_list()...")
        #print("populate_factory_list() called")
        #print("Files found:", list(self.core.factory_dir.glob("*")))
        self.listFactoryFiles.clear()
        self.populate_factory_list()
        QMessageBox.information(self, "Factory Saved", f"Factory saved: {filename}")
        matching_items = self.listFactoryFiles.findItems(filename, Qt.MatchFlag.MatchExactly)
        # Select factory after saving it
        if matching_items:
            self.listFactoryFiles.setCurrentItem(matching_items[0])


    def delete_current_factory(self):
        factory_name = self.FactoryFilename.text().strip()
        if factory_name:
            self.core.delete_factory_file(factory_name)
            self.populate_factory_list()
            self.FactoryFilename.clear()
            QMessageBox.information(self, "Deleted", f"Factory '{factory_name}' has been deleted.")

    def new_factory(self):
        self.FactoryFilename.clear()
        for field in self.findChildren(QLineEdit):
            field.clear()
        self.factory_dirty = True


    def load_selected_factory(self, item):
        factory_name = item.text()
        factory_path = Path(self.config.get("FactoryLocation")) / factory_name
        factory_data = self.core.load_factory(factory_path)

        if not factory_data:
            QMessageBox.warning(self, "Error", f"Failed to load factory: {factory_name}")
            return

        self.FactoryFilename.setText(factory_name)
        # for field in self.findChildren(QLineEdit):
        #     key = field.objectName().upper()
        #     if key in factory_data:
        #         field.setText(factory_data[key])
        self.factory_dirty = False
  
        combo_key_map = {
            # QLineEdit
            "FactoryDescription":       "FACTORYDESCRIPTION",
            "NotifyDirectory":          "NOTIFYDIRECTORY",
            "OutputDirectory":          "OUTPUTDIRECTORY",

            # Video (QComboBox unless noted)
            "VideoCodec":               "VIDEOCODECS",
            "VideoWrapper":             "VIDEOWRAPPER",
            "VideoFrameRate":           "VIDEOFRAMERATE",     # <-- was VideoFramerate
            "VideoSize":                "VIDEOSIZE",
            "VideoTarget":              "VIDEOTARGET",
            "videoFiltersCombo":        "VIDEOFILTERS",       # <-- actual widget id
            "VideoPixFormat":           "VIDEOPIXFORMAT",
            "Threads":                  "THREADS",            # exists on DepPage
            "VideoAspect":              "ASPECT",
            "VideoBitrate":             "VIDEOBITRATE",
            "VideoProfile":             "VIDEOPROFILE",
            "VideoProfileLevel":        "VIDEOPROFILELEVEL",
            "VideoPreset":              "VIDEOPRESET",
            "VideoStreamID":            "VIDEOSTREAMID",      # QLineEdit
            "VideoGroupPicSize":        "GROUPPICSIZE",       # QLineEdit
            "VideoBFrames":             "BFRAMES",            # QLineEdit
            "FrameStrategy":            "FRAMESTRATEGY",
            "ForceFormat":              "FORCEFORMAT",
            "EncodeLength":             "ENCODELENGTH",       # QLineEdit
            "VideoStartTimeOffset":     "STARTTIMEOFFSET",    # QLineEdit

            # Subtitles
            "SubtitleCodecs":           "SUBTITLECODECS",

            # Audio
            "AudioCodec":               "AUDIOCODECS",
            "AudioBitrate":             "AUDIOBITRATE",
            "AudioSampleRate":          "AUDIOSAMPLERATE",    # <-- was AudioSamplerate
            "AudioExtension":           "AUDIOFILEEXTENSION", # <-- was AudioFileExtension
            "audioFiltersCombo":        "AUDIOFILTERS",       # <-- actual widget id
            "AudioChannels":            "AUDIOCHANNELS",
            "AudioStreamID":            "AUDIOSTREAMID",      # QLineEdit
            "AudioTag":                 "AUDIOTAG",           # on DepPage, QLineEdit

            # Manual options (QLineEdit)
            "ManualOptions":            "MANUALOPTIONS",
            "ManualOptionsInput":       "MANUALOPTIONSINPUT",

            # Streaming
            "ForceFormatInputVideo":    "FORCEFORMATINPUTVIDEO",
            "ForceFormatInputAudio":    "FORCEFORMATINPUTAUDIO",
            "streamInputVideo":         "STREAMINPUTVIDEO",   # QLineEdit
            "streamInputAudio":         "STREAMINPUTAUDIO",   # QLineEdit 
            "streamRTMPUrl":            "STREAMRTMPURL",      # QLineEdit
            "streamKey":                "STREAMKEY",          # QLineEdit
            "StreamingFactoryName":     "STREAMINGFACTORYNAME",

            # TQS / low latency (combos/checkboxes exist; booleans handled separately)
            "tqsSizeCombo":             "TQSSIZE",
            # checkIncludeTQS → INCLUDETQS      (bool Yes/No or True/False)
            # checkLowLatencyInput → LOWLATENCYINPUT
            # checkMapAVInputs → AUTOMAPAV

            # Deprecated we still serialize as blanks (don’t map to UI):
            # OUTPUTFILESUFFIX, FFMXPROGRAM, RUNFROM, FTP*, FACTORYLINKS, FACTORYEMAIL*
        }



        DEFAULTS = {
            "STREAMINGFACTORYNAME": "",
            "INCLUDETQS":           "True",   # Designer default = checked
            "TQSSIZE":              "512",    # Designer default
            "LOWLATENCYINPUT":      "False",
            "AUTOMAPAV":            "False",
        }

        for w in self.findChildren((QLineEdit, QComboBox, QCheckBox)):
            key = combo_key_map.get(w.objectName())
            if not key:
                continue
            raw = (factory_data.get(key, DEFAULTS.get(key, "")) or "")

            if isinstance(w, QLineEdit):
                w.setText(raw)

            elif isinstance(w, QComboBox):
                val = (raw or "").strip()
                if val == "":
                    if w.isEditable():
                        w.setEditText("")
                        w.setCurrentIndex(-1)
                    elif w.count() > 0:
                        w.setCurrentIndex(0)
                    continue
                idx = w.findText(val)
                if idx < 0:
                    w.addItem(val)
                    idx = w.findText(val)
                w.setCurrentIndex(idx)

            elif isinstance(w, QCheckBox):
                s = str(raw).strip().lower()
                w.setChecked(s in ("true", "1", "yes", "on"))


    def populate_factory_list(self):
        self.core.reload_factory_files()  # Now cleaner and centralized
        self.listFactoryFiles.clear()
        for path in sorted(self.core.factory_files, key=lambda p: p.name.lower()):
            self.listFactoryFiles.addItem(path.name)
            
    # Import, Export and Backup Factories =========================================================
    def import_factory(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "Import Factory", "", "All Files (*)")
        if not file_path:
            return

        try:
            src_path = Path(file_path)
            filename = src_path.name
            dest_path = self.core.factory_dir / filename

            if dest_path.exists():
                msg_box = QMessageBox(self)
                msg_box.setWindowTitle("Factory Exists")
                msg_box.setText(f"Factory '{filename}' already exists.")
                msg_box.setInformativeText("Do you want to overwrite it or rename the import?")
                overwrite = msg_box.addButton("Overwrite", QMessageBox.ButtonRole.AcceptRole)
                rename = msg_box.addButton("Rename", QMessageBox.ButtonRole.ActionRole)
                cancel = msg_box.addButton("Cancel", QMessageBox.ButtonRole.RejectRole)
                msg_box.exec()

                clicked = msg_box.clickedButton()
                if clicked == cancel:
                    return
                elif clicked == rename:
                    new_name, ok = QFileDialog.getSaveFileName(self, "Rename Factory As", str(dest_path))
                    if not ok or not new_name:
                        return
                    dest_path = Path(new_name)

            shutil.copy(src_path, dest_path)
            self.populate_factory_list()
            QMessageBox.information(self, "Import Successful", f"Factory '{dest_path.name}' imported.")

        except Exception as e:
            QMessageBox.critical(self, "Import Failed", f"Could not import factory:\n{e}")


    def export_factory(self):
        selected_item = self.listFactoryFiles.currentItem()
        if not selected_item:
            QMessageBox.warning(self, "No Factory Selected", "Select a factory to export.")
            return

        factory_name = selected_item.text()
        factory_path = self.core.factory_dir / factory_name

        dialog = ExportFactoryDialog(factory_name, factory_path, self)
        if dialog.exec():
            dest_path_str, portable = dialog.get_export_info()
            if not dest_path_str:
                QMessageBox.warning(self, "No Destination", "Please specify a destination path.")
                return

            dest_path = Path(dest_path_str)
            success, message = export_factory_logic(factory_path, dest_path, portable)
            if success:
                QMessageBox.information(self, "Export Successful", message)
            else:
                QMessageBox.critical(self, "Export Failed", message)


    

    def backup_factories(self):
        timestamp = datetime.now().strftime("%Y-%m-%d")
        default_name = f"Factories-Backup-{timestamp}.zip"
        zip_path_str, _ = QFileDialog.getSaveFileName(
            self, "Save Backup As", default_name, "ZIP Archives (*.zip)"
        )
        if not zip_path_str:
            return

        zip_path = Path(zip_path_str)
        success, message = backup_factories_zip(self.core.factory_dir, zip_path)

        if success:
            QMessageBox.information(self, "Backup Complete", message)
        else:
            QMessageBox.critical(self, "Backup Failed", message)



    # ============================
    #     Global Config Logic
    # ============================
    def save_global_config(self):
        self.config.set("CompanyNameGlobal", self.CompanyNameGlobal.text())
        self.config.set("AppleDelaySeconds", self.AppleDelaySecondsGlobal.text())
        self.config.set("FactoryLocation", self.PathtoFactoriesGlobal.text().strip())
        self.config.set("DefaultFactory", self.DefaultFactoryGlobal.currentText())
 
        # CPU/GPU concurrency with safe parsing
        try:
            cpu_n = max(1, int(self.CpuMaxConcurrentJobsGlobal.value()))
        except Exception:
            cpu_n = 1
        try:
            gpu_n = max(1, int(self.GpuMaxConcurrentJobsGlobal.value()))
        except Exception:
            gpu_n = 2

        self.config.set("MaxConcurrentJobsCPU", str(cpu_n))
        self.config.set("MaxConcurrentJobsGPU", str(gpu_n))

        # keep the existing global fallback too
        raw = (self.MaxConcurrentJobsGlobal.text() or "").strip()
        try:
            n = int(raw);  n = 1 if n < 1 else n
        except Exception:
            n = 1
        self.config.set("MaxConcurrentJobs", str(n))



                
        self.config.save()
        QMessageBox.information(self, "Saved", "Global settings saved to ~/.freefactoryrc")

    def select_notify_directory(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Notify Directory")
        if directory:
            self.NotifyDirectory.setText(directory)

    def select_output_directory(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Output Directory")
        if directory:
            self.OutputDirectory.setText(directory)

    # ============================
    #     Dialog Actions
    # ============================
    def show_license(self):
        license_path = Path(__file__).parent.parent / "license.txt"
        if license_path.exists():
            with open(license_path, "r") as f:
                license_text = f.read()
        else:
            license_text = "License file not found."

        dialog = LicenseDialog(license_text, self)
        dialog.exec()

    def show_about(self):
        dialog = AboutDialog(self)
        dialog.exec()


    # ============================
    #     Preview Command Logic
    # ============================
    def on_generate_command(self):
        input_path = Path("input.filename")
        factory_name = self.FactoryFilename.text().strip()
        if not factory_name:
            QMessageBox.warning(self, "No Factory Selected", "Please select or enter a factory first.")
            return

        factory_path = Path(self.config.get("FactoryLocation")) / factory_name
        factory_data = self.core.load_factory(factory_path)
        if not factory_data:
            QMessageBox.warning(self, "Error", f"Could not load factory: {factory_path}")
            return

        cmd = self.core.build_ffmpeg_command(input_path, factory_data, preview=True)
        self.PreviewCommandLine.setText(" ".join(cmd))


    # ============================
    #     End __init__ Stub
    # ============================


# ============================
#     End Main Application Stub
# ============================



# ============================
#         Entry Point
# ============================
if __name__ == "__main__":
    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    app = QApplication(sys.argv)
    app.setStyle('Fusion')
    window = FreeFactoryApp()
    window.show()
    sys.exit(app.exec())
