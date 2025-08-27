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
import atexit

from pathlib import Path
from datetime import datetime

from PyQt6.QtCore import Qt, QThread, QTimer, QUrl
from PyQt6.QtGui import QPixmap, QDesktopServices
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QListWidgetItem, QMessageBox,
    QTableWidgetItem, QDialog, QVBoxLayout, QPlainTextEdit,
    QPushButton, QFileDialog, QHeaderView, QLabel, QComboBox,
    QLineEdit, QMenu, QCheckBox, QTextEdit, QTextBrowser
)
from PyQt6 import QtCore
from PyQt6.uic import loadUi

from config_manager import ConfigManager
from core import FFmpegWorker, FreeFactoryCore, FFmpegWorkerZone
from droptextedit import DropTextEdit
from ffmpeghelp import FFmpegHelpDialog

from ffstreaming import (
    StreamWorker, start_single_stream, stop_single_stream,
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
        self.active_streams_by_row = {}   # row_uid -> worker
        self._stream_row_seq = 0          # monotonic uid for stream rows


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
        self.CpuMaxConcurrentJobsGlobal.setValue(int(self.config.get("MaxConcurrentJobsCPU", "1") or 1))
        self.GpuMaxConcurrentJobsGlobal.setValue(int(self.config.get("MaxConcurrentJobsGPU", "2") or 2))
        self.MaxConcurrentJobsGlobal.setValue(int(self.config.get("MaxConcurrentJobs", "0") or 0))

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
                

    # Set up the Dictionary for all Widgets and Factory keys
    def _combo_key_map(self) -> dict[str, str]:
        # QLineEdit
        return {
            "FactoryDescription":       "FACTORYDESCRIPTION",       # QLineEdit
            "NotifyDirectory":          "NOTIFYDIRECTORY",          # QLineEdit
            "OutputDirectory":          "OUTPUTDIRECTORY",          # QLineEdit

            # Video
            "VideoCodec":               "VIDEOCODECS",              # QComboBox
            "VideoWrapper":             "VIDEOWRAPPER",             # QComboBox
            "VideoFrameRate":           "VIDEOFRAMERATE",           # QComboBox
            "VideoSize":                "VIDEOSIZE",                # QComboBox
            "videoFiltersCombo":        "VIDEOFILTERS",             # QComboBox
            "VideoPixFormat":           "VIDEOPIXFORMAT",           # QComboBox
            #"Threads":                  "THREADS",                  # Removed
            "VideoAspect":              "ASPECT",                   # QComboBox
            "VideoBitrate":             "VIDEOBITRATE",             # QComboBox
            "checkMatchMinMaxBitrate":  "MATCHMINMAXBITRATE",       # QCheckBox
            "VideoProfile":             "VIDEOPROFILE",             # QComboBox
            "VideoProfileLevel":        "VIDEOPROFILELEVEL",        # QComboBox
            "VideoPreset":              "VIDEOPRESET",              # QComboBox
            "VideoStreamID":            "VIDEOSTREAMID",            # QLineEdit
            "VideoGroupPicSize":        "GROUPPICSIZE",             # QLineEdit
            "VideoBFrames":             "BFRAMES",                  # QLineEdit
            "FrameStrategy":            "FRAMESTRATEGY",            # QComboBox
            "ForceFormat":              "FORCEFORMAT",              # QComboBox
            "EncodeLength":             "ENCODELENGTH",             # QLineEdit
            "VideoStartTimeOffset":     "STARTTIMEOFFSET",          # QLineEdit

            # Subtitles
            "SubtitleCodecs":           "SUBTITLECODECS",           # QComboBox

            # Audio
            "AudioCodec":               "AUDIOCODECS",              # QComboBox
            "AudioBitrate":             "AUDIOBITRATE",             # QComboBox
            "AudioSampleRate":          "AUDIOSAMPLERATE",          # QComboBox
            "AudioExtension":           "AUDIOFILEEXTENSION",       # QComboBox
            "audioFiltersCombo":        "AUDIOFILTERS",             # QComboBox
            "AudioChannels":            "AUDIOCHANNELS",            # QComboBox
            "AudioStreamID":            "AUDIOSTREAMID",            # QLineEdit

            # Manual options
            "ManualOptionsOutput":      "MANUALOPTIONSOUTPUT",      # QLineEdit
            "ManualOptionsInput":       "MANUALOPTIONSINPUT",       # QLineEdit

            # Streaming
            "ForceFormatInputVideo":    "FORCEFORMATINPUTVIDEO",    # QComboBox
            "ForceFormatInputAudio":    "FORCEFORMATINPUTAUDIO",    # QComboBox
            "streamInputVideo":         "STREAMINPUTVIDEO",         # QComboBox
            "streamInputAudio":         "STREAMINPUTAUDIO",         # QComboBox
            "streamRTMPUrl":            "STREAMRTMPURL",            # QLineEdit
            "streamKey":                "STREAMKEY",                # QLineEdit
            "checkIncludeTQS":          "INCLUDETQS",               # QCheckBox
            "checkLowLatencyInput":     "LOWLATENCYINPUT",          # QCheckBox
            "checkMapAVInputs":         "AUTOMAPAV",                # QCheckBox
            "tqsSizeCombo":             "TQSSIZE",                  # QComboBox
            "StreamMgrMode":            "STREAMMGRMODE",            # QComboBox
            "checkReadFilesRealTime":   "READFILESREALTIME",        # QCheckBox
            
            # Pre/Post Processing Options
            "EnableFactory":            "ENABLEFACTORY",            # QCheckBox
            "DeleteConversionLogs":     "DELETECONVERSIONLOGS",     # QCheckBox
            "DeleteSource":             "DELETESOURCE",             # QCheckBox
            
            #Recording Fields
            "RecordInput":              "RECORDINPUT",
            "RecordOutputFolder":       "RECORDFOLDER",
            "RecordFilename":           "RECORDFILENAME",
        }



    # ============================
    #       UI Setup Logic
    # ============================
    def setup_ui(self):
        self.SaveFFConfigGlobal.clicked.connect(self.save_global_config)
        
        self.LoadFactoryTools.clicked.connect(self.launch_factory_tools)
        
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
        
        if hasattr(self, "AddVideoStreamFile"):
            self.AddVideoStreamFile.clicked.connect(self._on_add_video_stream_file)
        if hasattr(self, "AddAudioStreamFile"):
            self.AddAudioStreamFile.clicked.connect(self._on_add_audio_stream_file)
        
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
        
        
        # Set up the Menu Items
        self.actionNewFactory.triggered.connect(self.new_factory)
        self.actionSaveFactory.triggered.connect(self.save_current_factory)
        self.actionDeleteFactory.triggered.connect(self.delete_current_factory)
        self.actionExitProgram.triggered.connect(self.close)

        self.actionOpenFactoryTools.triggered.connect(self.launch_factory_tools)
        self.actionFreeFactory_Manual.triggered.connect(self.open_manual)
        self.actionAbout_QT.triggered.connect(QApplication.instance().aboutQt)
        self.actionAboutFFmpeg.triggered.connect(self.show_about_ffmpeg)
        self.actionAboutFreeFactory.triggered.connect(self.show_about_dialog_existing)


 
        
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
        
        self.buttonAddNotifyDir.clicked.connect(self._add_notify_folder)
        self.RemoveNotifyFolders.clicked.connect(self._remove_notify_folder)

        # Populate on startup:
        for p in self.config.get_notify_folders():
            self.listNotifyFolders.addItem(p)

        # FreeFactory Clear Preview and Dropzone Buttons        
        self.clearPreviewButton.clicked.connect(lambda: self.PreviewCommandLine.clear())
        self.clearDropZoneButton.clicked.connect(lambda: self.dropZone.clear())

        # Ghost MinMaxBitrate checkbox if VideoBitrate is empty (uses _update_minmax_lock_state method below)
        self.VideoBitrate.currentTextChanged.connect(self._update_minmax_lock_state)
        self.checkMatchMinMaxBitrate.toggled.connect(self._update_minmax_lock_state)
        self._update_minmax_lock_state()

 
 
 
 
 
        # after loading factories & building tabs
        if hasattr(self, "_wire_stream_tab_minimal"):
            self._wire_stream_tab_minimal()

 
 
 
 
 
 
 
 
 
 
        

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


    # Method for ghosting the Lock Min/Max Bitrate whenever no VideoBitrate is selected.
    def _update_minmax_lock_state(self):
        has_bitrate = bool(self.VideoBitrate.currentText().strip())
        self.checkMatchMinMaxBitrate.setEnabled(has_bitrate)
        if not has_bitrate and self.checkMatchMinMaxBitrate.isChecked():
            self.checkMatchMinMaxBitrate.setChecked(False)

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
    #     Menu Support
    # ============================

    def launch_factory_tools(self):
        import sys
        from pathlib import Path
        import subprocess

        try:
            # Explicit path to FactoryTools.py
            factorytools_path = Path("/opt/FreeFactory/bin/FactoryTools.py")

            if not factorytools_path.exists():
                raise FileNotFoundError(f"{factorytools_path} does not exist")

            # Log path for debugging
            log_path = Path("/tmp/factorytools.log")

            with open(log_path, "w") as log_file:
                subprocess.Popen(
                    [sys.executable, str(factorytools_path)],
                    stdout=log_file,
                    stderr=log_file,
                    cwd=str(factorytools_path.parent)
                )
        except Exception as e:
            QMessageBox.critical(
                self,
                "Launch Error",
                f"Could not launch FactoryTools:\n{str(e)}"
            )

    def open_manual(self):
        # Replace with actual PDF/manual path
        QDesktopServices.openUrl(QUrl.fromLocalFile("/opt/FreeFactory/docs/FreeFactoryQT-Documentation.pdf"))

    def show_about_dialog_existing(self):
        dialog = AboutDialog(self)
        dialog.exec()

    def show_about_ffmpeg(self):
        try:
            ffmpeg_path = self.PathtoFFmpegGlobal.text().strip() or "ffmpeg"

            if os.path.isdir(ffmpeg_path):
                ffmpeg_path = os.path.join(ffmpeg_path, "ffmpeg")

            result = subprocess.run(
                [ffmpeg_path, "-version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                check=True
            )
            version_info = result.stdout

        except Exception as e:
            version_info = f"Failed to retrieve FFmpeg info:\n{str(e)}"

        dialog = QDialog(self)
        dialog.setWindowTitle("About FFmpeg")
        dialog.setMinimumSize(700, 500)

        layout = QVBoxLayout(dialog)

        browser = QTextBrowser()
        browser.setOpenExternalLinks(True)

        # Use the corrected logo path
        logo_path = Path("/opt/FreeFactory/Pics/ffmpeg.png")
        logo_tag = ""
        if logo_path.exists():
            logo_tag = f"<img src='file://{logo_path.as_posix()}' height='32' style='vertical-align:middle;'/> "

        # Wrap long preformatted lines using CSS
        browser.setHtml(f"""
            <h3>{logo_tag}FFmpeg</h3>
            <p>FFmpeg is a complete, cross-platform solution to record, convert, and stream audio and video.
            It includes libavcodec — the leading audio/video codec library.</p>
            <p>FFmpeg is free software licensed under the LGPL or GPL. Visit
            <a href='http://ffmpeg.org'>http://ffmpeg.org</a> for more information.</p>
            <hr>
            <div style="white-space: pre-wrap; font-family: monospace;">
    {version_info}
            </div>
        """)

        layout.addWidget(browser)

        close_btn = QPushButton("OK")
        close_btn.clicked.connect(dialog.accept)
        layout.addWidget(close_btn, alignment=Qt.AlignmentFlag.AlignRight)

        dialog.setLayout(layout)
        dialog.exec()


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
    
    def _on_add_video_stream_file(self):
        start_dir = getattr(self, "_last_stream_dir", os.path.expanduser("~"))
        fname, _ = QFileDialog.getOpenFileName(
            self,
            "Select video file to stream",
            start_dir,
            "Media files (*.mp4 *.mov *.mkv *.flv *.ts *.mxf *.avi *.webm *.m4v);;All files (*)",
        )
        if not fname:
            return

        # Fill the input box
        self.streamInputVideo.setText(fname)
        self._last_stream_dir = os.path.dirname(fname)
        
    def _on_add_audio_stream_file(self):
        start_dir = getattr(self, "_last_stream_dir", os.path.expanduser("~"))
        fname, _ = QFileDialog.getOpenFileName(
            self,
            "Select audio file to stream",
            start_dir,
            "Media files (*.flac *.mp3 *.aac *.wav *.ac3 *.dts *.m4a);;All files (*)",
        )
        if not fname:
            return

        # Fill the input box
        self.streamInputAudio.setText(fname)
        self._last_stream_dir = os.path.dirname(fname)
        

        # Ensure ForceFormatInputVideo == 'file' so core skips '-f' and TQS
        try:
            idx = self.ForceFormatInputVideo.findText("file")  # exact, lowercase
            if idx >= 0:
                self.ForceFormatInputVideo.setCurrentIndex(idx)
            elif self.ForceFormatInputVideo.isEditable():
                self.ForceFormatInputVideo.setEditText("file")
        except Exception:
            pass

        # nice UX ping
        if hasattr(self, "statusBar"):
            self.statusBar().showMessage("Selected stream file", 2000)
        
    
    def start_all_streams(self):
        """Start every idle row using the exact same path as manual Start."""
        rows = self.streamTable.rowCount()
        started = 0

        for row in range(rows):
            # fetch per-row metadata and worker (if any)
            item0 = self.streamTable.item(row, 0)
            if not item0:
                continue
            sd = item0.data(Qt.ItemDataRole.UserRole)
            row_uid = sd.get("row_uid") if sd else None

            # skip rows that are already running
            worker = None
            if row_uid is not None and hasattr(self, "active_streams_by_row"):
                worker = self.active_streams_by_row.get(row_uid)
            if worker:
                continue  # already live/starting

            # ensure a status cell exists, then set Starting…
            if not self.streamTable.item(row, STATUS_COL):
                self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Starting..."))
            else:
                self.streamTable.item(row, STATUS_COL).setText("Starting...")

            # IMPORTANT: use the same function as the single-row Start button
            self.start_stream_for_row(row)
            started += 1

        if hasattr(self, "statusBar"):
            try:
                self.statusBar().showMessage(f"Started {started} stream(s)", 3000)
            except Exception:
                pass

            
    def start_selected_stream(self):
        row = self.streamTable.currentRow()
        if row < 0:
            QMessageBox.warning(self, "No Selection", "Please select a stream row.")
            return
        self.start_stream_for_row(row)

    def start_stream_for_row(self, row: int):
        self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Starting..."))

        item0 = self.streamTable.item(row, 0)
        stream_data = item0.data(Qt.ItemDataRole.UserRole) if item0 else None
        if not stream_data:
            self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Error: No data"))
            return

        row_uid = stream_data.get("row_uid")
        if row_uid is None:
            self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Error: No row uid"))
            return

        # Mirror (optional)
        if hasattr(self, "streamFactorySelect"):
            self.streamFactorySelect.setCurrentText(stream_data.get("factory_name", ""))
        if hasattr(self, "streamRTMPUrl"):
            self.streamRTMPUrl.setText(stream_data.get("rtmp_url", ""))
        if hasattr(self, "streamKey"):
            self.streamKey.setText(stream_data.get("stream_key", ""))
        
        # Build & launch (use core.build_streaming_command)
        factory_name = (stream_data.get("factory_name") or "").strip()
        factory_root = self.config.get("FactoryLocation") or "/opt/FreeFactory/Factories"
        factory_path = Path(factory_root) / factory_name
        factory_data = self.core.load_factory(factory_path)

        fmt_v = (self.ForceFormatInputVideo.currentText() or "").strip().lower()
        fmt_a = (self.ForceFormatInputAudio.currentText() or "").strip().lower()

        full_output_url = stream_data.get("output_url", "")
        
        re_files = bool(self.checkReadFilesRealTime.isChecked())
        
        cmd = self.core.build_streaming_command(
            factory_data,
            video_input=stream_data.get("video_input", ""),
            audio_input=stream_data.get("audio_input", ""),
            video_input_format=fmt_v,
            audio_input_format=fmt_a,
            output_url=full_output_url,
            re_for_file_inputs=re_files,
        )

        print("DEBUG Streaming CMD:", cmd)  # optional

        if not cmd:
            self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Error: Bad command"))
            return

        full_output_url = cmd[-1]
        worker = StreamWorker(cmd, full_output_url)

        # Promote status changes
        worker.output.connect(lambda line, r=row: self._maybe_mark_live(r, line))
        worker.output.connect(self.streamLogOutput.appendPlainText)
        worker.finished.connect(lambda: self._on_stream_finished(row, full_output_url, False))
        worker.error.connect(lambda m: self._on_stream_error(row, full_output_url, m))

        # Store both mappings:
        if not hasattr(self, "active_streams_by_row"):
            self.active_streams_by_row = {}
        self.active_streams_by_row[row_uid] = worker

        if not hasattr(self, "active_streams"):
            self.active_streams = {}
        self.active_streams[full_output_url] = worker  # keep legacy URL map for Stop All etc.

        worker.start()
        self.streamLogOutput.appendPlainText(f"🟢 Started stream (row {row_uid}): {full_output_url}")
        
        if hasattr(self, "statusBar"):
            try:
                self.statusBar().showMessage(f"Started stream (row {row_uid})", 3000)
            except Exception:
                pass




    def _on_stream_finished(self, row: int, url: str, had_error: bool):
        # Resolve row_uid for cleanup
        row_uid = None
        try:
            item0 = self.streamTable.item(row, 0)
            sd = item0.data(Qt.ItemDataRole.UserRole) if item0 else None
            if sd:
                row_uid = sd.get("row_uid")
        except Exception:
            pass

        # Clean per-row map
        if row_uid is not None and hasattr(self, "active_streams_by_row"):
            self.active_streams_by_row.pop(row_uid, None)

        # Clean legacy URL map
        if hasattr(self, "active_streams") and url:
            self.active_streams.pop(url, None)

        # Update UI
        self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Error" if had_error else "Stopped"))
        
        if hasattr(self, "statusBar"):
            try:
                self.statusBar().showMessage("Stream finished", 3000)
            except Exception:
                pass




    def _maybe_mark_live(self, row: int, line: str):
        """
        Promote 'Starting...' → 'Live' as soon as ffmpeg emits meaningful output.
        Mark 'Error' on obvious error lines. No stopping/cleanup here.
        """
        try:
            tbl = self.streamTable
            if row < 0 or row >= tbl.rowCount():
                return
            txt = (line or "").strip()
            # Error heuristics (local, immediate)
            low = txt.lower()
            if any(k in low for k in ("error", "failed", "permission denied", "no such file")):
                tbl.setItem(row, STATUS_COL, QTableWidgetItem("Error"))
                return

            # Flip to Live once real stderr arrives and we're still "Starting…"
            item = tbl.item(row, STATUS_COL)
            cur = (item.text() if item else "").strip().lower()
            if cur.startswith("starting"):
                if txt and not txt.startswith("ffmpeg version"):
                    tbl.setItem(row, STATUS_COL, QTableWidgetItem("Live"))
        except Exception:
            pass


    def _on_stream_error(self, row: int, url: str, msg: str):
        # Log the error and funnel to the same finisher with had_error=True
        self.streamLogOutput.appendPlainText(f"🔴 {msg}")
        self._on_stream_finished(row, url, had_error=True)

    def stop_all_streams(self):
        stop_all_streams(self)
        
        if hasattr(self, "statusBar"):
            try:
                self.statusBar().showMessage("All streams stopped", 3000)
            except Exception:
                pass


    def stop_selected_stream(self):
        row = self.streamTable.currentRow()
        if row < 0:
            return

        item0 = self.streamTable.item(row, 0)
        stream_data = item0.data(Qt.ItemDataRole.UserRole) if item0 else None
        if not stream_data:
            self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Stopped"))
            return

        row_uid = stream_data.get("row_uid")
        worker = None
        if hasattr(self, "active_streams_by_row"):
            worker = self.active_streams_by_row.get(row_uid)

        if not worker:
            # Already gone; just mark UI
            self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Stopped"))
            return

        worker.stop()  # _on_stream_finished will finalize state
        
        if hasattr(self, "statusBar"):
            try:
                self.statusBar().showMessage("Stream stopped", 3000)
            except Exception:
                pass
                


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
            row_uid = stream_data.get("row_uid")
            worker = None
            if hasattr(self, "active_streams_by_row"):
                worker = self.active_streams_by_row.pop(row_uid, None)

            # Best-effort stop & legacy cleanup
            if worker:
                try:
                    worker.stop()
                except Exception:
                    pass

            url = stream_data.get("output_url")
            if hasattr(self, "active_streams") and url:
                self.active_streams.pop(url, None)

            self.streamLogOutput.appendPlainText(f"🔴 Removed row {row_uid} ({url or ''})")

        self.streamTable.removeRow(selected_row)
        
        if hasattr(self, "statusBar"):
            try:
                self.statusBar().showMessage("Stream removed", 3000)
            except Exception:
                pass

    


    def add_stream_to_table(self):
        row = self.streamTable.rowCount()
        self.streamTable.insertRow(row)

        # Assign stable row uid
        if not hasattr(self, "_stream_row_seq"):
            self._stream_row_seq = 0
        self._stream_row_seq += 1
        row_uid = self._stream_row_seq

        # Gather current UI values
        factory_name = self.streamFactorySelect.currentText().strip() if hasattr(self, "streamFactorySelect") else ""
        v_in   = self.streamInputVideo.text().strip()   if hasattr(self, "streamInputVideo") else ""
        a_in   = self.streamInputAudio.text().strip()   if hasattr(self, "streamInputAudio") else ""
        base   = self.streamRTMPUrl.text().strip()      if hasattr(self, "streamRTMPUrl")   else ""
        key    = self.streamKey.text().strip()          if hasattr(self, "streamKey")       else ""
        mux    = ""

        # Build full destination URL (with auth if streamAuthMode == 'url')
        full_url = base.rstrip("/")
        if key:
            full_url = f"{full_url}/{key}"

        if hasattr(self, "streamAuthMode") and self.streamAuthMode.currentText().strip() == "url":
            user = self.streamUsername.text().strip() if hasattr(self, "streamUsername") else ""
            pwd  = self.streamPassword.text().strip() if hasattr(self, "streamPassword") else ""
            if user and pwd and "@" not in full_url.split("://", 1)[-1]:
                scheme, rest = full_url.split("://", 1) if "://" in full_url else ("rtmp", full_url)
                full_url = f"{scheme}://{user}:{pwd}@{rest}"

        # Visible columns
        self.streamTable.setItem(row, 0, QTableWidgetItem(factory_name or "<factory>"))
        self.streamTable.setItem(row, 1, QTableWidgetItem(v_in))
        self.streamTable.setItem(row, 2, QTableWidgetItem(a_in))
        self.streamTable.setItem(row, 3, QTableWidgetItem(base))
        self.streamTable.setItem(row, 4, QTableWidgetItem(mux))
        self.streamTable.setItem(row, STATUS_COL, QTableWidgetItem("Idle"))

        # Stash per-row metadata (Start/Stop read only from here)
        stream_data = {
            "row_uid":      row_uid,        # <— NEW
            "factory_name": factory_name,
            "video_input":  v_in,
            "audio_input":  a_in,
            "rtmp_url":     base,           # base without key
            "stream_key":   key,
            "output_url":   full_url,       # full destination
        }
        item0 = self.streamTable.item(row, 0)
        item0.setData(Qt.ItemDataRole.UserRole, stream_data)

        self.streamTable.setCurrentCell(row, 0)


    def handle_stream_stopped(self, message):
        self.streamLogOutput.appendPlainText(f"🔴 Stream ended: {message}")


    # ============================
    #     Factory Management
    # ============================
    def save_current_factory(self):
        """
        Save the current factory to disk.
        - Uses ordered _combo_key_map() for primary fields
        - Preserves trailing slashes on NOTIFY/OUTPUT dirs
        - Keeps admin flags (DeleteSource, etc.)
        - Omits deprecated fields entirely
        """
        filename = self.FactoryFilename.text().strip()
        if not filename:
            QMessageBox.warning(self, "Missing Filename", "Please provide a factory filename.")
            return

        # Normalize the two directory fields (preserve trailing '/')
        notify_dir = (self.NotifyDirectory.text() or "").strip()
        output_dir = (self.OutputDirectory.text() or "").strip()
        if notify_dir and not notify_dir.endswith("/"):
            notify_dir += "/"
        if output_dir and not output_dir.endswith("/"):
            output_dir += "/"

        combo_key_map = self._combo_key_map()
        lines: list[str] = []

        # 1) Primary fields written in the order of the map
        for obj_name, key in combo_key_map.items():
            w = getattr(self, obj_name, None) or self.findChild(
                (QLineEdit, QComboBox, QCheckBox), obj_name
            )
            if not w:
                continue

            if isinstance(w, QLineEdit):
                val = (w.text() or "").strip()
            elif isinstance(w, QComboBox):
                val = (w.currentText() or "").strip()
            elif isinstance(w, QCheckBox):
                val = "True" if w.isChecked() else "False"
            else:
                continue

            if key == "NOTIFYDIRECTORY":
                val = notify_dir
            elif key == "OUTPUTDIRECTORY":
                val = output_dir

            lines.append(f"{key}={val}")

        # 2) Admin flags intentionally *not* in the map (factory-level)
        #lines += [
            #f"DELETESOURCE={'Yes' if getattr(self, 'DeleteSource', None) and self.DeleteSource.isChecked() else 'No'}",
            #f"DELETECONVERSIONLOGS={'Yes' if getattr(self, 'DeleteConversionLogs', None) and self.DeleteConversionLogs.isChecked() else 'No'}",
            #f"ENABLEFACTORY={'Yes' if getattr(self, 'EnableFactory', None) and self.EnableFactory.isChecked() else 'No'}",
            #f"FREEFACTORYACTION={'Encode' if getattr(self, 'ActionEncode', None) and self.ActionEncode.isChecked() else 'Copy'}",
            #f"ENABLEFACTORYLINKING={'Yes' if getattr(self, 'EnableFactoryLinking', None) and self.EnableFactoryLinking.isChecked() else 'No'}",
        #]

        # 3) Optional: Streaming factory name if present
        if hasattr(self, "StreamingFactoryName"):
            val = (self.StreamingFactoryName.text() or "").strip()
            lines.append(f"STREAMINGFACTORYNAME={val}")

        # 4) Write file + refresh UI
        factory_path = self.core.factory_dir / filename
        try:
            factory_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
            self.factory_dirty = False

            self.listFactoryFiles.clear()
            self.populate_factory_list()
            QMessageBox.information(self, "Factory Saved", f"Factory saved: {filename}")

            matches = self.listFactoryFiles.findItems(filename, Qt.MatchFlag.MatchExactly)
            if matches:
                self.listFactoryFiles.setCurrentItem(matches[0])
        except Exception as e:
            QMessageBox.critical(self, "Save Error", f"Failed to save factory:\n{e}")

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

        # Force Mode → Off
        try:
            self.StreamMgrMode.setCurrentIndex(0)   # 0 == "Off"
            # keep UI in sync (enable/disable inputs, etc.)
            if hasattr(self, "update_stream_ui_state"):
                self.update_stream_ui_state()
        except Exception:
            pass
        
        # Don’t call .clear() on the QComboBox itself (that nukes items)
        try:
            self.ForceFormatInputVideo.setCurrentIndex(-1)
            self.ForceFormatInputVideo.setEditText("")
            self.ForceFormatInputAudio.setCurrentIndex(-1)
            self.ForceFormatInputAudio.setEditText("")
        except Exception:
            pass
        try:
            self.checkReadFilesRealTime.setChecked(False)
        except Exception:
            pass
        

        # Optional feedback
        if hasattr(self, "statusBar"):
            try:
                self.statusBar().showMessage("New Factory: fields cleared", 3000)
            except Exception:
                pass

    def load_selected_factory(self, item):
        self.PreviewCommandLine.clear()
        factory_name = item.text()
        factory_path = Path(self.config.get("FactoryLocation")) / factory_name
        factory_data = self.core.load_factory(factory_path)

        if not factory_data:
            QMessageBox.warning(self, "Error", f"Failed to load factory: {factory_name}")
            return

        self.FactoryFilename.setText(factory_name)
        self.factory_dirty = False
   
        combo_key_map = self._combo_key_map()

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
                
            # Load checkMatchMinMaxBitrate manually (if not in combo_key_map)
            #if hasattr(self, "checkMatchMinMaxBitrate"):
            #    val = factory_data.get("MATCHMINMAXBITRATE", "").strip().lower()
            #    self.checkMatchMinMaxBitrate.setChecked(val in ("true", "1", "yes", "on"))
            
        self._sync_stream_selector_to_builder(factory_name)
        self.update_stream_ui_state()



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
    def _add_notify_folder(self):
        d = QFileDialog.getExistingDirectory(self, "Add Notify Folder")
        if d:
            d = d.rstrip("/")
            if not any(self.listNotifyFolders.item(i).text() == d for i in range(self.listNotifyFolders.count())):
                self.listNotifyFolders.addItem(d)

    def _remove_notify_folder(self):
        for item in self.listNotifyFolders.selectedItems():
            self.listNotifyFolders.takeItem(self.listNotifyFolders.row(item))    
    
    
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
        # Global total concurrency (0 = unlimited)
        try:
            total_n = int(self.MaxConcurrentJobsGlobal.value())
        except Exception:
            total_n = 0
        if total_n < 0:
            total_n = 0
        
        self.config.set("MaxConcurrentJobsCPU", str(cpu_n))
        self.config.set("MaxConcurrentJobsGPU", str(gpu_n))
        self.config.set("MaxConcurrentJobs", str(total_n))


        # keep the existing global fallback too
        raw = (self.CpuMaxConcurrentJobsGlobal.text() or "").strip()
        if raw.isdigit():
            self.config.set("MaxConcurrentJobsCPU", raw)

        raw = (self.GpuMaxConcurrentJobsGlobal.text() or "").strip()
        if raw.isdigit():
            self.config.set("MaxConcurrentJobsGPU", raw)
            
            

        # Inside your "save global config" method:
        folders = [self.listNotifyFolders.item(i).text().strip()
                for i in range(self.listNotifyFolders.count())
                if self.listNotifyFolders.item(i).text().strip()]
        self.config.set_notify_folders(folders)

        # Update the runner shell script line
        from ffnotifyservice import write_notify_runner_sh
        write_notify_runner_sh(self)

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
    #     Stream Tab Mode Handlers
    # ============================
    
    def _sync_stream_selector_to_builder(self, factory_name: str):
        """Preselect builder’s factory in streamFactorySelect if its mode != Off."""
        if not factory_name or not hasattr(self, "streamFactorySelect"):
            return
        try:
            mode = (self._read_stream_mode_from_factory(factory_name) or "").upper()
            if mode == "OFF":
                return
            # Make sure the selector is filtered & fresh (non-Off only)
            self._rebuild_stream_factory_selector()
            w = self.streamFactorySelect
            if hasattr(w, "findText"):
                idx = w.findText(factory_name)
                if idx >= 0:
                    w.setCurrentIndex(idx)
        except Exception:
            pass


    # --- Stream tab wiring: OFF vs STREAM + selector filter (exclude OFF) ---
    def _factory_root(self) -> Path:
        return Path(self.config.get("FactoryLocation", "/opt/FreeFactory/Factories"))

    def _read_stream_mode_from_factory(self, name: str) -> str:
        """Return normalized STREAMMGRMODE for a factory name; '' if not found."""
        from pathlib import Path
        if not name:
            return ""
        root = self._factory_root()

        # support: plain file (no extension), <name>.factory, or <name>/factory
        candidates = [
            root / name,                   # plain file (your common case)
            root / f"{name}.factory",      # legacy/alt layout
            root / name / "factory",       # directory layout
        ]
        for p in candidates:
            if p.exists() and p.is_file():
                try:
                    for line in p.read_text(errors="ignore").splitlines():
                        line = line.strip()
                        if not line or line.startswith("#") or "=" not in line:
                            continue
                        k, v = line.split("=", 1)
                        if k.strip().upper() == "STREAMMGRMODE":
                            return (v or "").strip().upper()
                except Exception:
                    pass
        return ""

    def _rebuild_stream_factory_selector(self):
        """Populate streamFactorySelect with all factories where STREAMMGRMODE != OFF."""
        if not hasattr(self, "streamFactorySelect"):
            print("[stream] selector missing; skip")
            return

        root = self._factory_root()
        names = []
        if root.exists():
            for p in sorted(root.iterdir(), key=lambda x: x.name.lower()):
                if p.is_file() or p.is_dir():
                    fname = p.name if p.is_file() else p.name  # use visible file/dir name
                    mode = self._read_stream_mode_from_factory(fname)
                    if mode != "OFF":
                        names.append(fname)

        w = self.streamFactorySelect
        try: w.blockSignals(True)
        except Exception: pass
        if hasattr(w, "clear"): w.clear()
        for n in names:
            try: w.addItem(n)
            except Exception: pass
        try: w.blockSignals(False)
        except Exception: pass

        #print(f"[stream] rebuilt selector: {len(names)} factories (root={root})")
        if not names:
            try:
                all_entries = [p.name for p in sorted(root.iterdir())]
                print(f"[stream] note: directory contains {len(all_entries)} entries: {all_entries[:10]}…")
            except Exception:
                pass


    def _selected_stream_factory_name(self) -> str:
        """Get current text from streamFactorySelect (supports combo or list)."""
        if not hasattr(self, "streamFactorySelect"):
            return ""
        w = self.streamFactorySelect
        # QComboBox path
        if hasattr(w, "currentText"):
            return (w.currentText() or "").strip()
        # QListWidget/LB path
        try:
            item = w.currentItem()
            return (item.text() if item else "") .strip()
        except Exception:
            return ""

    def _stream_table_has_selection(self) -> bool:
        try:
            tbl = getattr(self, "streamTable", None)
            if tbl and tbl.selectionModel():
                return tbl.selectionModel().hasSelection()
        except Exception:
            pass
        return False

    def update_stream_ui_state(self):
        """
        Mode gating only (no table/worker logic).
        - Off: disable inputs + Add + Start + StartAll
        - Stream/Record/Record+Stream: enable inputs + Add + StartAll
        Start row button: only force-disable in Off; otherwise leave table logic to manage.
        Stop/StopAll: always enabled.
        """
        raw = (self.StreamMgrMode.currentText() or "Off").strip().lower() \
            if hasattr(self, "StreamMgrMode") and hasattr(self.StreamMgrMode, "currentText") else "off"
        is_off = (raw == "off")

        # Inputs that follow the mode (include your checkboxes/combos)
        input_names = [
            "ForceFormatInputVideo","ForceFormatInputAudio",
            "streamRTMPUrl","streamKey","streamInputVideo","streamInputAudio",
            "streamFactorySelect","streamAuthMode","streamUsername","streamPassword",
            "checkIncludeTQS","tqsSizeCombo","checkMapAVInputs","checkLowLatencyInput",
            "AddVideoStreamFile","streamInputProfile","RecordInput","RecordOutputFolder",
            "RecordFilename","buttonRecordOutputFolder","StartStopRecording",
            "checkReadFilesRealTime",
        ]
        for name in input_names:
            if hasattr(self, name):
                try: getattr(self, name).setEnabled(not is_off)
                except Exception: pass

        # Buttons we explicitly gate
        for name in ("AddNewStream", "StartAllStreams"):
            if hasattr(self, name):
                try: getattr(self, name).setEnabled(not is_off)
                except Exception: pass

        # StartStream: only force-disable in Off; otherwise leave as-is for table logic
        if hasattr(self, "StartStream"):
            try:
                if is_off:
                    self.StartStream.setEnabled(False)
                # else: do not change; table logic will set appropriately
            except Exception:
                pass

        # Stop buttons: always enabled
        for name in ("StopStream", "StopAllStreams"):
            if hasattr(self, name):
                try: getattr(self, name).setEnabled(True)
                except Exception: pass
            
            
        # Buttons that follow the mode (fully enabled for Stream/Record/Record+Stream)
        for name in ("AddNewStream", "StartStream", "StartAllStreams"):
            if hasattr(self, name):
                try: getattr(self, name).setEnabled(not is_off)
                except Exception: pass
        
        for name in ("StopStream", "StopAllStreams"):
            if hasattr(self, name):
                try: getattr(self, name).setEnabled(True)
                except Exception: pass
    

        #print(f"[stream] mode={raw} -> inputs={not is_off}, add/startAll={not is_off}, start_row={'free' if not is_off else 'forced off'}, stop/stopAll=always on")


    def _wire_stream_tab_minimal(self):
        """Call this once after UI is built and factories are loaded."""
        # Build filtered selector (exclude OFF)
        self._rebuild_stream_factory_selector()

        # React to Mode changes and selector changes
        if hasattr(self, "StreamMgrMode") and hasattr(self.StreamMgrMode, "currentTextChanged"):
            self.StreamMgrMode.currentTextChanged.connect(lambda _=None: self.update_stream_ui_state())

        # QComboBox has currentTextChanged; QListWidget has currentItemChanged
        w = getattr(self, "streamFactorySelect", None)
        if w:
            # Try both; only one will exist.
            if hasattr(w, "currentTextChanged"):
                w.currentTextChanged.connect(lambda _=None: self.update_stream_ui_state())
            elif hasattr(w, "currentItemChanged"):
                w.currentItemChanged.connect(lambda *_: self.update_stream_ui_state())

        # Initial pass
        self.update_stream_ui_state()

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
    import sys, signal, subprocess, atexit
    from PyQt6.QtWidgets import QApplication

    # Let Ctrl+C kill the app cleanly
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    # TTY saver/restorer so you don't have to type `reset` after exit
    _TTY_STATE = None
    if sys.stdout.isatty():
        try:
            _TTY_STATE = subprocess.check_output(["stty", "-g"]).strip().decode()
        except Exception:
            _TTY_STATE = None

        def _restore_tty_state():
            try:
                if _TTY_STATE:
                    subprocess.run(["stty", _TTY_STATE], check=False)
                else:
                    subprocess.run(["stty", "sane"], check=False)
                # reset attrs, show cursor, re-enable wrap
                sys.stdout.write("\x1b[0m\x1b[?25h\x1b[?7h")
                sys.stdout.flush()
            except Exception:
                pass

        atexit.register(_restore_tty_state)

    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = FreeFactoryApp()  # <-- your QMainWindow subclass
    window.show()
    sys.exit(app.exec())
