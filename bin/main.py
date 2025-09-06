#!/usr/bin/env python3
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
import time

from pathlib import Path
from datetime import datetime

from PyQt6.QtCore import Qt, QThread, QTimer, QUrl, QProcess
from PyQt6.QtGui import QPixmap, QDesktopServices, QPalette, QColor
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QListWidgetItem, QMessageBox,
    QTableWidgetItem, QDialog, QVBoxLayout, QPlainTextEdit,
    QPushButton, QFileDialog, QHeaderView, QLabel, QComboBox,
    QLineEdit, QMenu, QCheckBox, QTextEdit, QTextBrowser, QLCDNumber
)
from PyQt6 import QtCore
from PyQt6.uic import loadUi
from PyQt6 import uic

from config_manager import ConfigManager
from core import FFmpegWorker, FreeFactoryCore, FFmpegWorkerZone
from droptextedit import DropTextEdit
from ffmpeghelp import FFmpegHelpDialog
from version import get_version

from ffstreaming import (
    StreamWorker, start_single_stream, stop_single_stream,
    start_all_streams, stop_all_streams,
    handle_stream_stopped
)

from ffnotifyservice import (
    connect_notify_service_controls,
    update_notify_service_mode_display,
    show_notify_service_menu,
)
from importexport import ExportFactoryDialog, export_factory_logic, backup_factories_zip

# Absolute path to the real script location, even when launched via a symlink
# This allows FreeFactory to launch from say /usr/local/bin/FreeFactory symlink
APP_DIR = Path(__file__).resolve().parent          # /opt/FreeFactory/bin
ROOT_DIR = APP_DIR.parent                          # /opt/FreeFactory (if you need it)

def asset(*parts: str) -> Path:
    """
    Build an absolute path to an app asset (.ui, icons, etc.).
    Tries APP_DIR first, then ROOT_DIR for convenience.
    """
    p = APP_DIR.joinpath(*parts)
    if not p.exists():
        q = ROOT_DIR.joinpath(*parts)
        if q.exists():
            return q
    return p  # return even if missing so you get a clear error



STATUS_COL = 5


# --- copy-lock widget lists (module-level constants) ---
VIDEO_COPY_WIDGETS = [
    "VideoSize",
    "VideoPixFormat",
    "VideoProfile",
    "VideoProfileLevel",
    "VideoBitrate",
    "VideoFrameRate",
    "VideoAspect",
    "VideoPreset",
    "videoFiltersCombo",
    "VideoBFrames",
    "VideoGroupPicSize",
    "FrameStrategy",
    "VideoFormat",
]

AUDIO_COPY_WIDGETS = [
    "AudioExtension",   # remove if you decide it's not needed
    "AudioBitrate",
    "AudioSampleRate",
    "AudioChannels",
    "audioFiltersCombo",
]



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


from version import get_version   # at the top of the file

class AboutDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("About FreeFactory")
        self.setMinimumSize(335, 235)
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

        about_text = f"""
        <b>FreeFactory</b><br>
        Version {get_version()}<br>
        An open-source professional media<br>conversion frontend for FFmpeg.<br><br>
        © 2013–2025 James Hines and Karl Swisher<br>
        Licensed under <a href='https://www.gnu.org/licenses/gpl-3.0.html'>GPLv3</a><br>
        <a href='https://github.com/lacojim/FreeFactoryQT'>github.com/lacojim/FreeFactoryQT</a>
        """
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
        self._is_closing = False          # Prevents noisey exiting
        self._is_stopping_recording = False


        #ui_path = Path(__file__).parent / "FreeFactory-tabs.ui"
        #loadUi(ui_path, self)
        UI_PATH = asset("FreeFactory-tabs.ui")
        uic.loadUi(str(UI_PATH), self)

        self.setup_ui()
        self.populate_factory_list()
        self.setWindowTitle(f"FreeFactoryQT - {get_version()}")

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
            "VideoFormat":              "VIDEOFORMAT",              # QComboBox
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
            "streamAuthMode":           "STREAMAUTHMODE",           # QComboBox
            "streamUsername":           "STREAMUSERNAME",           # QLineEdit
            "streamPassword":           "STREAMPASSWORD",           # QLineEdit
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
        self.listFactoryFiles.itemClicked.connect(self.load_selected_factory)   # For Mouse clicks
        self.listFactoryFiles.itemActivated.connect(self.load_selected_factory) # For Keyboard cursor and Enter
        
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
        
        # Recording Widgets Support
        # --- Recording UI ---
        self.buttonRecordOutputFolder.clicked.connect(self._on_choose_record_output_folder)
        self.StartStopRecording.clicked.connect(self._on_toggle_recording)
        self._update_record_button()  # initialize label
        
        self._init_record_timer()
        self.RecordElapsed.setStyleSheet("color: red; font-weight: bold; background-color: black; font-size: 12pt;")
       
        
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
        self.actionAddFactorytoStreamTable.triggered.connect(self.add_stream_to_table)
       
        # ---- Simple, idempotent codec wiring ----
        for combo, handler in [
            (getattr(self, "VideoCodec", None), self._on_vcodec_changed),
            (getattr(self, "AudioCodec", None), self._on_acodec_changed),
        ]:
            if combo:
                try: combo.currentTextChanged.disconnect()
                except Exception: pass
                combo.currentTextChanged.connect(handler)

 
        
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
    #     Ghost Widgets when Copy
    #     Codec is selected Helpers
    # ============================

    def _is_copy_text(self, s: str) -> bool:
        return (s or "").strip().lower() == "copy"

    def _w(self, name: str):
        return getattr(self, name, None)

    def _lbl(self, name: str):
        return getattr(self, f"l_{name}", None)

    def _set_enabled(self, obj, on: bool):
        if obj is not None:
            try: obj.setEnabled(on)
            except Exception: pass

    def _clear_value(self, w):
        if w is None:
            return
        # Only clear "safe" inputs; never destroy combo items.
        try:
            if hasattr(w, "setText"):
                w.setText("")
                return
            if hasattr(w, "setPlainText"):
                w.setPlainText("")
                return
            if hasattr(w, "setValue"):
                # Reset to minimum if available, else 0
                v = w.minimum() if hasattr(w, "minimum") else 0
                w.setValue(v)
                return
            if hasattr(w, "isEditable") and hasattr(w, "setEditText") and w.isEditable():
                w.setEditText("")  # editable combo only
                return
        except Exception:
            pass

    def _apply_group_copy_lock(self, names: list[str], *, is_copy: bool, clear_on_disable: bool):
        # Toggle widgets + their "l_<name>" labels; optionally clear values when disabling.
        for name in names:
            w = self._w(name)
            l = self._lbl(name)                 # <-- the "l_" lookup happens here
            self._set_enabled(w, not is_copy)
            self._set_enabled(l, not is_copy)
            if is_copy and clear_on_disable:
                self._clear_value(w)

    def _apply_video_copy_lock(self, *, clear_on_disable: bool):
        is_copy = self._is_copy_text(self._w("VideoCodec").currentText()) if self._w("VideoCodec") else False
        self._apply_group_copy_lock(VIDEO_COPY_WIDGETS, is_copy=is_copy, clear_on_disable=clear_on_disable)

    def _apply_audio_copy_lock(self, *, clear_on_disable: bool):
        is_copy = self._is_copy_text(self._w("AudioCodec").currentText()) if self._w("AudioCodec") else False
        self._apply_group_copy_lock(AUDIO_COPY_WIDGETS, is_copy=is_copy, clear_on_disable=clear_on_disable)
 
    # ============================
    #     End Ghost Widget Helpers
    # ============================

    # ============================
    #     Copy Codec Handlers
    # ============================
    def _on_vcodec_changed(self, new_text: str):
        # During factory load, never clear; just apply enabled/disabled state.
        if getattr(self, "_loading_factory", False):
            self._apply_video_copy_lock(clear_on_disable=False)
            return
        # On user change: clear dependents iff switching to "copy".
        self._apply_video_copy_lock(clear_on_disable=self._is_copy_text(new_text))

    def _on_acodec_changed(self, new_text: str):
        if getattr(self, "_loading_factory", False):
            self._apply_audio_copy_lock(clear_on_disable=False)
            return
        self._apply_audio_copy_lock(clear_on_disable=self._is_copy_text(new_text))






    # ─────────────────────────────────────────────────────────────────────────────
    # Group ghosting helpers + unified mode gating
    # ─────────────────────────────────────────────────────────────────────────────

    def _get_stream_mode(self, *_):
        """
        Return one of the four canonical modes:
        'Off', 'Stream', 'Record', 'Record+Stream'
        Falls back to 'Off' if text isn't recognized.
        """
        mode_widget = getattr(self, "StreamMgrMode", None)
        if mode_widget is not None and hasattr(mode_widget, "currentText"):
            txt = (mode_widget.currentText() or "").strip()
            if txt in ("Off", "Stream", "Record", "Record+Stream"):
                return txt
        return "Off"


    def _iter_widgets_by_names(self, names):
        """Yield (name, widget, label_widget_or_None) for each existing name."""
        for name in names:
            w = getattr(self, name, None)
            if w is None:
                continue
            lbl = getattr(self, f"l_{name}", None)
            yield name, w, lbl

    def _set_enabled_pair(self, w, lbl, enabled: bool):
        """Enable/disable a widget and its label (if present)."""
        try:
            w.setEnabled(enabled)
        except Exception:
            pass
        if lbl is not None:
            try:
                lbl.setEnabled(enabled)
            except Exception:
                pass

    def _ghost_group_by_names(self, names, enabled: bool):
        """Enable/disable an entire group of named widgets (plus their labels)."""
        for _, w, lbl in self._iter_widgets_by_names(names):
            self._set_enabled_pair(w, lbl, enabled)

    # ─────────────────────────────────────────────────────────────────────────────
    # Group membership (root lists) — labels auto-detected via l_<name>
    # Adjust names if you later rename widgets in Qt Designer.
    # ─────────────────────────────────────────────────────────────────────────────

    def _stream_controls_names(self):
        """Everything considered part of the Live Streaming Controls group."""
        return [
            # Format selectors shared with streaming
            "ForceFormatInputVideo", "ForceFormatInputAudio",
            # Core streaming controls
            "streamRTMPUrl", "streamKey",
            "streamInputVideo", "streamInputAudio",
            "streamFactorySelect", "streamAuthMode",
            "streamUsername", "streamPassword",
            # TQS / mapping / latency / profiles, etc.
            "checkIncludeTQS", "tqsSizeCombo",
            "checkMapAVInputs", "checkLowLatencyInput",
            "streamInputProfile", "AddVideoStreamFile",
            # Buttons that follow mode (not the Stop buttons)
            "AddNewStream", "StartAllStreams",
            "checkReadFilesRealTime",
        ]

    def _record_controls_names(self):
        """Everything considered part of the Recording Settings group."""
        return [
            "groupRecordSettings",
            "RecordInput",
            "RecordOutputFolder",
            "RecordFilename",
            "buttonRecordOutputFolder",   # ← added
            "StartStopRecording",
            "RecordAudioSource",          # ← added (label optional)
            "PreviewRecInput",            # ← added (label optional)
            "RecordLog",
        ]

    def _stream_table_names(self):
        """
        The streams table group (row actions live here).
        We will override Stop buttons after group ghosting.
        """
        return [
            "groupStreamsTable",
            # If row action buttons are not children-only, include them explicitly:
            "StartStream", "StopStream", "StartAllStreams", "StopAllStreams",
        ]

    # ─────────────────────────────────────────────────────────────────────────────
    # Unified, authoritative state machine for Streaming/Recording UI
    # ─────────────────────────────────────────────────────────────────────────────

    def update_stream_ui_state(self, *_):
        """
        Single source of truth for mode-based ghosting:
        Modes:
            - Off             → stream: off, record: off, table: off (Stop/StopAll re-enabled)
            - Stream          → stream: on,  record: off, table: on
            - Record          → stream: off, record: on,  table: off (Stop/StopAll re-enabled)
            - Record+Stream   → stream: on,  record: on,  table: on
        Additional rules:
            - Always ghost/enabled labels with their widgets (l_<name>).
            - Do NOT clear values here (pure enable/disable).
            - StartStream is forcibly disabled only in Off mode.
            - StopStream / StopAllStreams remain clickable even when the table is ghosted.
        """
        mode = (self._get_stream_mode() or "Off").strip()

        # Decide group states
        if mode == "Stream":
            stream_enabled, record_enabled, table_enabled = True, False, True
        elif mode == "Record":
            stream_enabled, record_enabled, table_enabled = False, True, False
        elif mode in ("Record+Stream", "Stream+Record"):
            stream_enabled, record_enabled, table_enabled = True, True, True
        else:  # Off
            stream_enabled, record_enabled, table_enabled = False, False, False

        # Sweep groups
        self._ghost_group_by_names(self._stream_controls_names(), stream_enabled)
        self._ghost_group_by_names(self._record_controls_names(), record_enabled)
        self._ghost_group_by_names(self._stream_table_names(), table_enabled)

        # Special-case: Stop buttons must stay enabled even if the table group is ghosted.
        for stop_btn_name in ("StopStream", "StopAllStreams"):
            btn = getattr(self, stop_btn_name, None)
            if btn is not None:
                try:
                    btn.setEnabled(True)
                except Exception:
                    pass
            lbl = getattr(self, f"l_{stop_btn_name}", None)
            if lbl is not None:
                try:
                    lbl.setEnabled(True)
                except Exception:
                    pass

        # Special-case: StartStream is force-disabled in Off
        start_btn = getattr(self, "StartStream", None)
        if start_btn is not None:
            try:
                start_btn.setEnabled(mode != "Off")
            except Exception:
                pass

        # Optional: update any status badges/text here.
        # self._refresh_stream_status_badge(mode)










 
    # ============================
    #     End Streams and Conversions
    #     on Exit w/confirmation
    #     UI Only
    # ============================
    def closeEvent(self, event):
        self._is_closing = True

        # UI-managed activity only (do NOT touch FreeFactoryConversion.py)
        active_threads = list(getattr(self, "active_threads", []))
        has_threads = any(getattr(t, "isRunning", lambda: False)() for t, _ in active_threads)
        has_streams = bool(getattr(self, "active_streams_by_row", {}))

        if has_streams or has_threads:
            box = QMessageBox(self)
            box.setIcon(QMessageBox.Icon.Warning)
            box.setWindowTitle("Exit FreeFactory?")
            box.setText("You currently have active streams and/or conversions running.<br>Exiting will abort all (UI-managed only).")
            box.setInformativeText("Do you want to exit now?")
            box.setStandardButtons(QMessageBox.StandardButton.Cancel | QMessageBox.StandardButton.Ok)
            box.setDefaultButton(QMessageBox.StandardButton.Cancel)
            result = box.exec()
            if result == QMessageBox.StandardButton.Cancel:
                event.ignore()
                return

            # Audit trail (UI-only shutdown)
            print("[FreeFactory] Exit requested — stopping UI-managed streams/conversions")

        # Stop UI-owned recording if running (independent of service)
        try:
            self._stop_recording_proc()   # <- idempotent, safe if already None/finished
        except Exception:
            pass


        # Stop UI-managed streams only
        try:
            # This should terminate only the ffmpeg processes spawned by the UI’s stream table workers
            self.stop_all_streams()
        except Exception:
            pass

        # Wind down UI conversion threads only
        try:
            for (thread, _worker) in active_threads:
                try:
                    thread.quit()
                    thread.wait(3000)
                except Exception:
                    pass
        except Exception:
            pass

        super().closeEvent(event)
        

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
        """Open FFmpeg Help dialog with the configured ffmpeg binary."""
        import os, shutil
        from ffmpeghelp import FFmpegHelpDialog

        ffmpeg_path = (self.PathtoFFmpegGlobal.text() or "").strip() or "ffmpeg"
        if os.path.isdir(ffmpeg_path):
            ffmpeg_path = os.path.join(ffmpeg_path, "ffmpeg")
        ffmpeg_path = shutil.which(ffmpeg_path) or ffmpeg_path

        self._ffmpeg_help_dialog = FFmpegHelpDialog(title, args, self, ffmpeg_path=ffmpeg_path)
        self._ffmpeg_help_dialog.show()



    # ============================
    #     Recording Controls
    # ============================
    def _on_toggle_recording(self):
        # Stop?
        if getattr(self, "_recording_proc", None) and \
        self._recording_proc.state() != self._recording_proc.ProcessState.NotRunning:
            self._stop_recording_proc()
            self.statusBar().showMessage("Recording stopped", 3000)
            return

            try:
                # Graceful then hard stop
                self._recording_proc.write(b"q")
                self._recording_proc.waitForFinished(1500)
            except Exception:
                pass
            try:
                if self._recording_proc.state() != self._recording_proc.ProcessState.NotRunning:
                    self._recording_proc.kill()
                    self._recording_proc.waitForFinished(1500)
            except Exception:
                pass
            self._recording_proc.deleteLater()
            self._recording_proc = None
            self.statusBar().showMessage("Recording stopped", 3000)
            self._update_record_button()
            return

        # Start
        factory_name = self.FactoryFilename.text().strip()
        if not factory_name:
            QMessageBox.warning(self, "Recording", "Please select or enter a factory first.")
            return

        # Load factory data
        factory_path = Path(self.config.get("FactoryLocation")) / factory_name
        factory_data = self.core.load_factory(factory_path)
        if not factory_data:
            QMessageBox.warning(self, "Recording", f"Failed to load factory: {factory_name}")
            return

        # Inputs & formats
        video_input = (self.RecordInput.text().strip() if hasattr(self, "RecordInput") else "") or ":0.0+0,0"
        video_fmt = "x11grab" if video_input.startswith(":") else "file"
        audio_input = "default"  # later: add a widget if you want a selectable source
        audio_fmt = "pulse"
        out_path = self._resolve_record_output_path()
        re_for_files = bool(getattr(self, "checkReadFilesRealTime", None) and self.checkReadFilesRealTime.isChecked())

        # Build command via core (reuses Builder settings: fps/size/bitrate/pix_fmt/etc.)
        cmd = self.core.build_recording_command(
            factory_data,
            video_input=video_input,
            audio_input=audio_input,
            video_input_format=video_fmt,
            audio_input_format=audio_fmt,
            output_path=str(out_path),
            re_for_file_inputs=re_for_files,
        )


        # Resolve ffmpeg program path from config or PATH
        ffmpeg_bin = (self.config.get("PathtoFFmpegGlobal") or "").strip()

        if not ffmpeg_bin:
            # use PATH
            program = shutil.which("ffmpeg") or "ffmpeg"
        else:
            # normalize, allow user to give "/usr/bin" or "/usr/bin/"
            p = ffmpeg_bin.rstrip("/")
            if os.path.isdir(p):
                p = os.path.join(p, "ffmpeg")
            program = p

        # If user gave just "ffmpeg" or a bare name, try PATH
        program = shutil.which(program) or program

        # Clean arguments (ensure they don't contain the program name)
        arguments = cmd
        if arguments and Path(arguments[0]).name.lower() in ("ffmpeg", "ffmpeg.exe"):
            arguments = arguments[1:]

        # Debug (just for visibility; args are passed as list, not this string)
        print(f"[record] launching: {program} " + " ".join(shlex.quote(a) for a in arguments))

        # Optional sanity check
        from PyQt6.QtCore import QFileInfo
        fi = QFileInfo(program)
        if not (fi.exists() and fi.isExecutable()):
            from PyQt6.QtWidgets import QMessageBox
            QMessageBox.critical(self, "Recording", f"ffmpeg not found or not executable:\n{program}")
            return

        # create the process and hook logs BEFORE starting
        proc = QProcess(self)
        proc.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        proc.readyReadStandardError.connect(
            lambda: print(bytes(proc.readAllStandardError()).decode("utf-8", "replace"), end="")
        )
        proc.errorOccurred.connect(self._on_record_error)
        proc.finished.connect(lambda code, _st: self._on_recording_finished(code))

        proc.start(program, arguments)

        if not proc.waitForStarted(3000):
            from PyQt6.QtWidgets import QMessageBox
            QMessageBox.critical(self, "Recording", f"Failed to start ffmpeg:\n{program}\n(see console for args)")
            return

        self._recording_proc = proc
        self.statusBar().showMessage(f"Recording → {Path(arguments[-1]).name}", 4000)
        self._update_record_button()
        self._style_record_button(True) # Make it red
        self._start_record_timer()


    def _on_recording_finished(self, code: int):
        self.statusBar().showMessage(
            "Recording finished" if code == 0 else f"Recording exited ({code})", 4000
        )
        self._stop_recording_proc()
        self._style_record_button(False) # Turn off Red
        self._stop_record_timer()
        
####### Recording Elapsed Time
    def _init_record_timer(self):
        """Call once during setup_ui()."""
        self._rec_timer = QTimer(self)
        self._rec_timer.setInterval(1000)  # 1s tick
        self._rec_timer.timeout.connect(self._tick_record_timer)
        self._rec_started_at = None
        # Optional: ensure label exists before we touch it
        if hasattr(self, "RecordElapsed") and self.RecordElapsed:
            try:
                self.RecordElapsed.setText("00:00:00")
            except Exception:
                pass

    def _start_record_timer(self):
        self._rec_started_at = time.monotonic()
        if hasattr(self, "RecordElapsed") and self.RecordElapsed:
            try:
                self.RecordElapsed.setText("00:00:00")
            except Exception:
                pass
        self._rec_timer.start()

    def _stop_record_timer(self):
        self._rec_timer.stop()
        self._rec_started_at = None

    def _tick_record_timer(self):
        if self._rec_started_at is None:
            return
        elapsed = int(time.monotonic() - self._rec_started_at)
        h, rem = divmod(elapsed, 3600)
        m, s = divmod(rem, 60)
        text = f"{h:02d}:{m:02d}:{s:02d}"
        if hasattr(self, "RecordElapsed") and self.RecordElapsed:
            try:
                self.RecordElapsed.setText(text)
            except Exception:
                pass





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
        self.listFactoryFiles.clearSelection()
        for field in self.findChildren(QLineEdit):
            field.clear()
        self.factory_dirty = True

        self.streamUsername.clear()
        self.streamPassword.clear()

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
        
        self._apply_video_copy_lock(clear_on_disable=False)
        self._apply_audio_copy_lock(clear_on_disable=False)



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
        self.config.set("DefaultFactory", self.DefaultFactoryGlobal.currentText())
        self.config.set("FactoryLocation", self.PathtoFactoriesGlobal.text().strip())
        self.config.set("PathtoFFmpegGlobal", self.PathtoFFmpegGlobal.text().strip())

 
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
    #   (Builder/Streamer/Recorder)
    # ============================
    def on_generate_command(self):
        factory_name = self.FactoryFilename.text().strip()
        if not factory_name:
            QMessageBox.warning(self, "No Factory Selected", "Please select or enter a factory first.")
            return

        factory_path = Path(self.config.get("FactoryLocation")) / factory_name
        factory_data = self.core.load_factory(factory_path)
        if not factory_data:
            QMessageBox.warning(self, "Error", f"Could not load factory: {factory_path}")
            return

        mode = (self.StreamMgrMode.currentText() or "Off").strip().lower() if hasattr(self, "StreamMgrMode") else "off"
        if mode == "record":
            video_input = (self.RecordInput.text().strip() if hasattr(self, "RecordInput") else "") or ":0.0+0,0"
            video_fmt = "x11grab" if video_input.startswith(":") else "file"
            audio_input = "default"
            audio_fmt = "pulse"
            out_path = self._resolve_record_output_path()
            re_for_files = bool(getattr(self, "checkReadFilesRealTime", None) and self.checkReadFilesRealTime.isChecked())

            cmd = self.core.build_recording_command(
                factory_data,
                video_input=video_input,
                audio_input=audio_input,
                video_input_format=video_fmt,
                audio_input_format=audio_fmt,
                output_path=str(out_path),
                re_for_file_inputs=re_for_files,
            )
        else:
            # …your existing preview path (conversion/stream)…
            cmd = self.core.build_ffmpeg_command(Path("input.filename"), factory_data, preview=True)

        self.PreviewCommandLine.setText(" ".join(cmd))


    # ============================
    #     Recording Mode Helpers 
    # ============================
    def _resolve_record_output_path(self) -> Path:
        folder = (self.RecordOutputFolder.text().strip() if hasattr(self, "RecordOutputFolder") else "") \
                or str(Path.home() / "Videos" / "FreeFactory")
        folder_path = Path(folder); folder_path.mkdir(parents=True, exist_ok=True)

        template = (self.RecordFilename.text().strip() if hasattr(self, "RecordFilename") else "") \
                or "%Y%m%d-%H%M%S_{factory}.mp4"
        factory_name = self.FactoryFilename.text().strip() or "factory"
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        fname = template.replace("%Y%m%d-%H%M%S", ts).replace("{factory}", factory_name)
        if not fname.lower().endswith(".mp4"):
            fname += ".mp4"
        return folder_path / fname
    # Record Output Path
    def _resolve_record_output_path(self) -> Path:
        # Folder
        folder = (self.RecordOutputFolder.text().strip()
                if hasattr(self, "RecordOutputFolder") else "")
        if not folder:
            folder = str(Path.home() / "Videos" / "FreeFactory")
        folder_path = Path(folder)
        folder_path.mkdir(parents=True, exist_ok=True)

        # Filename template: defaults to %Y%m%d-%H%M%S_{factory}.mp4
        tmpl = (self.RecordFilename.text().strip()
                if hasattr(self, "RecordFilename") else "")
        if not tmpl:
            tmpl = "%Y%m%d-%H%M%S_{factory}.mp4"

        factory_name = self.FactoryFilename.text().strip() if hasattr(self, "FactoryFilename") else "factory"
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        fname = tmpl.replace("%Y%m%d-%H%M%S", ts).replace("{factory}", factory_name)
        if not fname.lower().endswith(".mp4"):
            fname += ".mp4"
        return folder_path / fname

    # Pick Recording Output Folder
    def _on_choose_record_output_folder(self):
        start_dir = self.RecordOutputFolder.text().strip() or str(Path.home())
        folder = QFileDialog.getExistingDirectory(self, "Choose Recording Folder", start_dir)
        if folder:
            self.RecordOutputFolder.setText(folder)

    # Recording Button Toggle 
    def _update_record_button(self):
        # Treat presence of a running QProcess as “recording”
        running = getattr(self, "_recording_proc", None) and self._recording_proc.state() != self._recording_proc.ProcessState.NotRunning
        self.StartStopRecording.setText("Stop Recording" if running else "Start Recording")
    
    # Recording Button Red when Recording
    def _style_record_button(self, recording: bool):
        if recording:
            # vivid red, readable text, rounded, a bit of padding
            self.StartStopRecording.setStyleSheet("""
                QPushButton {
                    background: #c62828;
                    color: white;
                    border: 1px solid #7f1d1d;
                    border-radius: 6px;
                    padding: 4px 12px;
                    font-weight: 600;
                }
                QPushButton:hover { background: #b71c1c; }
                QPushButton:pressed { background: #8e1313; }
            """)
        else:
            self.StartStopRecording.setStyleSheet("")  # back to default theme

    # Fix for AttributeError: 'NoneType' object has no attribute 'deleteLater'
    def _stop_recording_proc(self):
        """Idempotent stop/cleanup for the recording QProcess."""
        proc = getattr(self, "_recording_proc", None)
        if not proc:
            return

        self._is_stopping_recording = True
        try:
            proc.write(b"q")
            proc.waitForFinished(500)
        except Exception:
            pass

        try:
            if proc.state() != proc.ProcessState.NotRunning:
                proc.terminate()                  # <— prefer graceful terminate
                if not proc.waitForFinished(800):
                    proc.kill()                   # <— only if needed
                    proc.waitForFinished(800)
        except Exception:
            pass

        try:
            proc.deleteLater()
        except Exception:
            pass

        self._recording_proc = None
        self._is_stopping_recording = False

        if not getattr(self, "_is_closing", False):
            self._update_record_button()


    def _on_record_error(self, err):
        if getattr(self, "_is_closing", False) or getattr(self, "_is_stopping_recording", False):
            return  # intentional shutdown — stay quiet
        print(f"[record] QProcess error: {err}")









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


    def _wire_stream_tab_minimal(self):
        """Call this once after UI is built and factories are loaded."""
        # Prevent duplicates if setup_ui() ever calls us twice
        if getattr(self, "_stream_tab_wired", False):
            self.update_stream_ui_state()
            return
        self._stream_tab_wired = True

        # React to StreamMgrMode changes
        mode = getattr(self, "StreamMgrMode", None)
        if mode and hasattr(mode, "currentTextChanged"):
            mode.currentTextChanged.connect(
                self.update_stream_ui_state,
                type=Qt.ConnectionType.UniqueConnection
            )

        # React to stream factory selector changes (QComboBox or QListWidget)
        sel = getattr(self, "streamFactorySelect", None)
        if sel:
            if hasattr(sel, "currentTextChanged"):      # QComboBox
                sel.currentTextChanged.connect(
                    self.update_stream_ui_state,
                    type=Qt.ConnectionType.UniqueConnection
                )
            elif hasattr(sel, "currentItemChanged"):    # QListWidget
                sel.currentItemChanged.connect(
                    self.update_stream_ui_state,
                    type=Qt.ConnectionType.UniqueConnection
                )

        # Initial pass so the UI reflects the current mode on load
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
