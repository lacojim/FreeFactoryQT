# main.py

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
# Entry point for the FreeFactory PyQt6 application

import sys
import os
import subprocess
from pathlib import Path

from PyQt6.QtCore import Qt, QThread, QTimer
from PyQt6.QtGui import QPixmap
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QListWidgetItem, QMessageBox,
    QTableWidgetItem, QDialog, QVBoxLayout, QPlainTextEdit,
    QPushButton, QFileDialog, QHeaderView, QLabel
)
from PyQt6.uic import loadUi

from config_manager import ConfigManager
from core import FFmpegWorker, FreeFactoryCore, FFmpegWorkerZone
from droptextedit import DropTextEdit
from ffmpeghelp import FFmpegHelpDialog



class LicenseDialog(QDialog):
    def __init__(self, license_text, parent=None):
        super().__init__(parent)
        self.setWindowTitle("FreeFactory License")
        self.setMinimumSize(600, 400)

        layout = QVBoxLayout()

#=======GPL logo path
        script_dir = os.path.dirname(os.path.abspath(__file__))
        logo_path = os.path.abspath(os.path.join(script_dir, "..", "Pics", "gplv3-88x31.png"))

        logo_label = QLabel()
        if os.path.exists(logo_path):
            pixmap = QPixmap(logo_path)
            logo_label.setPixmap(pixmap)
            logo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            layout.addWidget(logo_label)

#=======License text area
        text_edit = QPlainTextEdit()
        text_edit.setReadOnly(True)
        text_edit.setPlainText(license_text)
        layout.addWidget(text_edit)

#=======Close button
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

#=======Load FreeFactory About logo
        logo_label = QLabel()
        script_dir = os.path.dirname(os.path.abspath(__file__))
        logo_path = os.path.abspath(os.path.join(script_dir, "..", "Pics", "FreeFactoryProgramLogo.png"))
        if os.path.exists(logo_path):
            pixmap = QPixmap(logo_path).scaled(128, 128, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
            logo_label.setPixmap(pixmap)
            logo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            layout.addWidget(logo_label)

#=======About text
        about_text = """\
<b>FreeFactory</b><br>
Version 1.1<br>
An open-source professional media conversion app.<br><br>
© 2013–2025 Jim Hines and Karl Swisher<br>
Licensed under <a href='https://www.gnu.org/licenses/gpl-3.0.html'>GPLv3</a><br>
<a href='https://github.com/lacojim/FreeFactoryQT'>github.com/lacojim/FreeFactoryQT</a>
"""
        text_label = QLabel(about_text)
        text_label.setOpenExternalLinks(True)
        text_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(text_label)

        # Close button
        close_btn = QPushButton("Close", self)
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn, alignment=Qt.AlignmentFlag.AlignCenter)

        self.setLayout(layout)

# Main app class
class FreeFactoryApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.config = ConfigManager() # Order is important here.
        ui_path = Path(__file__).parent / "FreeFactory-tabs.ui"
        loadUi(ui_path, self)
        
        self.factory_dirty = False  # This is for when changing factories without saving first

#=======Populate the DefaultFactoryGlobal combo box with factory list
        factory_names = sorted(Path("/opt/FreeFactory/Factories").glob("*"))
        factory_names = [f.stem for f in factory_names if f.is_file()]
        self.DefaultFactoryGlobal.addItems(factory_names)
        self.active_threads = []
        self.queue_paused = False

#====== Rebind promoted widget to real subclass for dropped media files
        self.dropZone: DropTextEdit  # for IDE type hinting
        self.core = FreeFactoryCore(self.config)
        #self.core = FreeFactoryCore()

        self.populate_factory_list()
        self.listFactoryFiles.itemClicked.connect(self.load_selected_factory)
        self.SaveFactory.clicked.connect(self.save_current_factory)
        self.DeleteFactory.clicked.connect(self.delete_current_factory)
        self.NewFactory.clicked.connect(self.new_factory)
        self.PreviewCommand.clicked.connect(self.on_generate_command)
        self.ViewLicense.clicked.connect(self.show_license)
        self.AboutFreeFactory.clicked.connect(self.show_about)
#====== Two drop zones. 
        self.dropZone.filesDropped.connect(self.handle_dropped_files)
        self.queueDropZone.filesDropped.connect(self.handle_dropped_files_to_queue)

#====== Connect directory selection tool buttons
        self.toolButton_notifyDir.clicked.connect(self.select_notify_directory)
        self.toolButton_outputDir.clicked.connect(self.select_output_directory)
        
#=======Queue Buttons:
        self.startQueueButton.clicked.connect(self.start_conversion_queue)
        self.clearQueueButton.clicked.connect(self.clear_conversion_queue)
        self.conversionQueueTable.setColumnWidth(0, 300)  # Input file
        self.conversionQueueTable.setColumnWidth(1, 300)  # Output file
        self.conversionQueueTable.setColumnWidth(2, 120)  # Status column
        self.conversionQueueTable.horizontalHeader().setStretchLastSection(True)
        self.pauseQueueButton.clicked.connect(self.pause_or_resume_queue)
        self.removeFromQueueButton.clicked.connect(self.remove_selected_from_queue)

#=======ConfigManager
        #self.config = ConfigManager() # This needs moved to the top of this Method.
        #print("CompanyNameGlobal from config:", self.config.get("CompanyNameGlobal")) #debug
        self.CompanyNameGlobal.setText(self.config.get("CompanyNameGlobal"))
        self.AppleDelaySecondsGlobal.setText(self.config.get("AppleDelaySeconds"))
        self.PathtoFFmpegGlobal.setText(self.config.get("PathtoFFmpegGlobal"))
        self.SaveFFConfigGlobal.clicked.connect(self.save_global_config)

#=======Populate DefaultFactoryGlobal ComboBox
        factory_names = [f.stem for f in self.core.factory_files]
        self.DefaultFactoryGlobal.clear()
        self.DefaultFactoryGlobal.addItems(factory_names)
#=======Populate PathtoFactoriesGlobal ComboBox        
        self.PathtoFactoriesGlobal.setText(self.config.get("FactoryLocation"))

#=======Select the saved default (if it exists)
        default_name = self.config.get("DefaultFactory")
        if default_name in factory_names:
            self.DefaultFactoryGlobal.setCurrentText(default_name)

            # Also select it in the list widget
            for i in range(self.listFactoryFiles.count()):
                item = self.listFactoryFiles.item(i)
                if item.text() == default_name:
                    self.listFactoryFiles.setCurrentRow(i)
                    self.load_selected_factory(item)
                    break

#===Help Buttons Connectors
        self.helpAllHelp.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Full FFmpeg Help", ["-h", "full"])
        )

        self.helpVCodecsAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Video Codecs", ["-codecs"])
        )

        self.helpACodecsAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Audio Codecs", ["-codecs"])
        )

        self.helpMuxersAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Muxers", ["-muxers"])
        )
        self.helpMuxersFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Encode Help: {self.helpMuxersFilter.text()}",
                ["-h", f"muxer={self.helpMuxersFilter.text()}"]
            )
        )
        self.helpVFiltersAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Video Filters", ["-filters"])
        )

        self.helpVFiltersFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Encode Help: {self.helpVFiltersFilter.text()}",
                ["-h", f"filter={self.helpVFiltersFilter.text()}"]
            )
        )

        self.helpAFiltersAll.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog("Audio Filters", ["-filters"])
        )

        self.helpAFiltersFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Encode Help: {self.helpAFiltersFilter.text()}",
                ["-h", f"filter={self.helpAFiltersFilter.text()}"]
            )
        )


        self.helpVCodecsFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Encoder Help: {self.helpVCodecsFilter.text()}",
                ["-h", f"encoder={self.helpVCodecsFilter.text()}"]
            )
        )

        self.helpACodecsFiltered.clicked.connect(
            lambda: self.open_ffmpeg_help_dialog(
                f"Encoder Help: {self.helpACodecsFilter.text()}",
                ["-h", f"encoder={self.helpACodecsFilter.text()}"]
            )
        )



#===File QUEUE FFmpegWorker
    def remove_selected_from_queue(self): #Remove From Queue Button Method.
        selected_rows = set()

        for item in self.conversionQueueTable.selectedItems():
            selected_rows.add(item.row())

        for row in sorted(selected_rows, reverse=True):
            self.conversionQueueTable.removeRow(row)

    def handle_dropped_files_to_queue(self, files):
        if not self.listFactoryFiles.currentItem():
            QMessageBox.warning(self, "No Factory Selected", "Please select a factory before dropping files.")
            return

        factory_name = self.FactoryFilename.text().strip()
        available_factories = [Path(f).stem for f in self.core.factory_files]

        if not factory_name or factory_name not in available_factories:
            QMessageBox.warning(self, "Invalid Factory", "Selected factory configuration is invalid.")
            return

        factory_data = self.core.load_factory(factory_name)

        for input_path in files:
            cmd = self.core.build_ffmpeg_command(input_path, factory_data)
            output_path = cmd[-1]  # Last argument is the output file
            self.add_file_to_queue(input_path, output_path)

#====Help Buttons
    def open_ffmpeg_help_dialog(self, title, args):
        # Keep a reference so it doesn't get garbage collected
        self._ffmpeg_help_dialog = FFmpegHelpDialog(title, args, self)
        self._ffmpeg_help_dialog.show()


    def add_file_to_queue(self, input_path, output_path):
        row_position = self.conversionQueueTable.rowCount()
        self.conversionQueueTable.insertRow(row_position)
        self.conversionQueueTable.setItem(row_position, 0, QTableWidgetItem(str(input_path)))
        self.conversionQueueTable.setItem(row_position, 1, QTableWidgetItem(str(output_path)))
        self.conversionQueueTable.setItem(row_position, 2, QTableWidgetItem("Queued"))

    def start_conversion_queue(self):
        self.current_queue_index = 0
        self.run_next_in_queue()

    def run_next_in_queue(self):
        if self.queue_paused:
            return  # Don’t process if paused

        if self.current_queue_index >= self.conversionQueueTable.rowCount():
            self.conversionProgressBar.setValue(100)
            return

        input_path = self.conversionQueueTable.item(self.current_queue_index, 0).text()
        output_path = self.conversionQueueTable.item(self.current_queue_index, 1).text()

        factory_name = self.FactoryFilename.text().strip()
        factory_data = self.core.load_factory(factory_name)
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
#=============End File Queue

#===Drag and Drop Support for dropZone FFmpegWorkerZone
    import subprocess
    
    def handle_dropped_files(self, files):
        if not self.listFactoryFiles.currentItem():
            QMessageBox.warning(self, "No Factory Selected", "Please select a factory before dropping files.")
            return

        factory_name = self.FactoryFilename.text().strip()
        print(f"Selected factory: '{factory_name}'")

        available_factories = [Path(f).stem for f in self.core.factory_files]
        print(f"Available factories: {available_factories}")

        if not factory_name or factory_name not in available_factories:
            QMessageBox.warning(self, "Invalid Factory", "Selected factory configuration is invalid.")
            return

        factory_data = self.core.load_factory(factory_name)
        print(f"Loaded factory data: {factory_data}")

        for file_path in files:
            self.dropZone.appendPlainText(f"🔄 Processing: {file_path}")

            try:
                cmd = self.core.build_ffmpeg_command(file_path, factory_data)
                self.dropZone.appendPlainText(f"⚙️ Running command:\n{' '.join(cmd)}")

                thread = QThread()
                worker = FFmpegWorkerZone(cmd)
                worker.moveToThread(thread)

                # Define what happens on success or failure
                worker.finished.connect(lambda msg, fp=file_path: self.dropZone.appendPlainText(f"{msg}\n✔️ File: {fp}"))
                worker.error.connect(lambda msg, fp=file_path: self.dropZone.appendPlainText(f"{msg}\n❌ File: {fp}"))

                # Cleanup
                thread.started.connect(worker.run)
                worker.finished.connect(thread.quit)
                worker.error.connect(thread.quit)
                worker.finished.connect(worker.deleteLater)
                worker.error.connect(worker.deleteLater)
                thread.finished.connect(thread.deleteLater)

                # Start the thread
                thread.start()
                # Keep a reference so it doesn't get destroyed early
                self.active_threads.append((thread, worker))

                # Clean up after the thread finishes
                def cleanup():
                    print(f"Cleaning up thread for: {file_path}")
                    self.active_threads = [
                        (t, w) for (t, w) in self.active_threads if t != thread
                    ]

                thread.finished.connect(cleanup)

            except Exception as e:
                self.dropZone.appendPlainText(f"⚠️ Exception preparing command: {str(e)}\n")


# ==Pause / Resume Queue Control
    def pause_or_resume_queue(self):
        self.queue_paused = not self.queue_paused

        if self.queue_paused:
            self.pauseQueueButton.setText("Resume Queue")
        else:
            self.pauseQueueButton.setText("Pause Queue")
            self.run_next_in_queue()  # Resume immediately if unpaused
            
#===ConfigManager Save Method
    def save_global_config(self):
        self.config.set("CompanyNameGlobal", self.CompanyNameGlobal.text())
        self.config.set("AppleDelaySeconds", self.AppleDelaySecondsGlobal.text())
        self.config.set("FactoryLocation", self.PathtoFactoriesGlobal.text().strip())
        self.config.set("DefaultFactory", self.DefaultFactoryGlobal.currentText())
        
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


#===Populate Factory List
    def populate_factory_list(self):
        self.core.factory_files = sorted([
            f for f in self.core.factory_dir.glob("*")
            if f.is_file() and f.name != ".directory"
        ], key=lambda f: f.name.lower())
        self.listFactoryFiles.clear()
        for factory_path in self.core.factory_files:
            item = QListWidgetItem(factory_path.name)
            self.listFactoryFiles.addItem(item)
            

    def load_selected_factory(self, item):
        filename = item.text()
        path = self.core.factory_dir / filename
        if not path.exists():
            return

        self.FactoryFilename.setText(filename)

        with open(path, 'r') as f:
            lines = f.readlines()

        factory_data = {}
        for line in lines:
            if '=' in line:
                key, value = line.strip().split('=', 1)
                factory_data[key.strip()] = value.strip()

#=======Populate QLineEdits (excluding FactoryFilename)
        for key in [
            "FactoryDescription", "NotifyDirectory", "OutputDirectory",
            "OutputFileSuffix", "FTPUrl", "FTPUsername", "FTPPassword", "FTPRemotePath",
            "EmailName", "EmailAddress", "ManualOptions", "PreviewCommandLine", 
            "VideoStreamID", "AudioStreamID"
        ]:
            widget = getattr(self, key, None)
            if widget:
                widget.setText(factory_data.get(key.upper(), ""))

#=======Custom key-to-field mapping for mismatched keys
        lineedit_key_map = {
            "VideoBFrames": "BFRAMES",
            "VideoGroupPicSize": "GROUPPICSIZE",
            "VideoStartTimeOffset": "STARTTIMEOFFSET",
            "VideoForceFormat": "FORCEFORMAT",
            "FrameStrategy": "FRAMESTRATEGY"
        }
        for widget_key, factory_key in lineedit_key_map.items():
            widget = getattr(self, widget_key, None)
            if widget:
                widget.setText(factory_data.get(factory_key, ""))

#=======Field-to-widget key remapping for mismatches
        combo_key_map = {
            "FFMxProgram": "FFMXPROGRAM",
            "VideoCodec": "VIDEOCODECS",
            "VideoWrapper": "VIDEOWRAPPER",
            "VideoFrameRate": "VIDEOFRAMERATE",
            "VideoSize": "VIDEOSIZE",
            "VideoBitrate": "VIDEOBITRATE",
            "VideoAspect": "ASPECT",
            "VideoTarget": "VIDEOTARGET",
            "VideoTags": "VIDEOTAGS",
            "SubtitleCodecs": "SUBTITLECODECS",
            "AudioCodec": "AUDIOCODECS",
            "AudioBitrate": "AUDIOBITRATE",
            "AudioSampleRate": "AUDIOSAMPLERATE",
            "AudioExtention": "AUDIOFILEEXTENSION",
            "AudioChannels": "AUDIOCHANNELS",
            "FTPProgram": "FTPPROGRAM",
            "Threads": "THREADS",
            "VideoPreset": "VIDEOPRESET"
        }

#=======Populate QComboBoxes
        for widget_key, factory_key in combo_key_map.items():
            widget = getattr(self, widget_key, None)
            if widget:
                widget.setCurrentText(factory_data.get(factory_key, ""))

#=======Populate QCheckBoxes
        for key in [
            "EnableFactory", "DeleteSource", "DeleteConversionLogs", "EnableEmail",
            "EnableFactoryLinking", "EnableFactoryGlobal", "RemoveSourceGlobal",
            "RemoveLogsGlobal", "FtpRemoveOutputGlobal", "EnableEmailGlobal",
            "FactoryLinkingGlobal"
        ]:
            widget = getattr(self, key, None)
            if widget:
                widget.setChecked(factory_data.get(key.upper(), "No") == "Yes")

#=======Populate QRadioButtons
        radio_map = {
            "RUNFROM": {"usr": "RunFromUsr", "opt": "RunFromOpt"},
            "FREEFRACTORYACTION": {"Copy": "ActionCopy", "Encode": "ActionEncode"}
        }
        for key, value_map in radio_map.items():
            selected = factory_data.get(key, "")
            widget_name = value_map.get(selected)
            if widget_name:
                button = getattr(self, widget_name, None)
                if button:
                    button.setChecked(True)

#========other methods remain unchanged ...
    def save_current_factory(self):
        filename = self.FactoryFilename.text().strip()
        if not filename:
            QMessageBox.warning(self, "Missing Filename", "Please provide a factory filename.")
            return

        filepath = self.core.factory_dir / filename

        lines = [
            f"FACTORYDESCRIPTION={self.FactoryDescription.text().strip()}",
            f"NOTIFYDIRECTORY={self.NotifyDirectory.text().strip()}",
            f"OUTPUTDIRECTORY={self.OutputDirectory.text().strip()}",
            "OUTPUTFILESUFFIX=",  # <— hardcoded empty line since this was removed from UI
            f"FFMXPROGRAM={self.FFMxProgram.currentText().strip()}",
            f"RUNFROM={'usr' if self.RunFromUsr.isChecked() else 'opt'}",
            f"FTPPROGRAM={self.FTPProgram.currentText().strip()}",
            f"FTPURL={self.FTPUrl.text().strip()}",
            f"FTPUSERNAME={self.FTPUsername.text().strip()}",
            f"FTPPASSWORD={self.FTPPassword.text().strip()}",
            f"FTPREMOTEPATH={self.FTPRemotePath.text().strip()}",
            f"FTPTRANSFERTYPE=asc",
            f"FTPDELETEAFTER=Yes",
            f"VIDEOCODECS={self.VideoCodec.currentText().strip()}",
            f"VIDEOWRAPPER={self.VideoWrapper.currentText().strip()}",
            f"VIDEOFRAMERATE={self.VideoFrameRate.currentText().strip()}",
            f"VIDEOSIZE={self.VideoSize.currentText().strip()}",
            f"VIDEOTARGET={self.VideoTarget.currentText().strip()}",
            f"VIDEOTAGS={self.VideoTags.currentText().strip()}",
            f"THREADS={self.Threads.currentText().strip()}",
            f"ASPECT={self.VideoAspect.currentText().strip()}",
            f"VIDEOBITRATE={self.VideoBitrate.currentText().strip()}",
            f"VIDEOPRESET={self.VideoPreset.currentText().strip()}",
            f"VIDEOSTREAMID={self.VideoStreamID.text().strip()}",
            f"GROUPPICSIZE={self.VideoGroupPicSize.text().strip()}",
            f"BFRAMES={self.VideoBFrames.text().strip()}",
            f"FRAMESTRATEGY={self.FrameStrategy.text().strip()}",
            f"FORCEFORMAT={self.VideoForceFormat.text().strip()}",
            f"STARTTIMEOFFSET={self.VideoStartTimeOffset.text().strip()}",
            f"SUBTITLECODECS={self.SubtitleCodecs.currentText().strip()}",
            f"AUDIOCODECS={self.AudioCodec.currentText().strip()}",
            f"AUDIOBITRATE={self.AudioBitrate.currentText().strip()}",
            f"AUDIOSAMPLERATE={self.AudioSampleRate.currentText().strip()}",
            f"AUDIOFILEEXTENSION={self.AudioExtention.currentText().strip()}",
            f"AUDIOTAG={self.AudioTag.text().strip() if hasattr(self, 'AudioTag') else ''}",
            f"AUDIOCHANNELS={self.AudioChannels.currentText().strip()}",
            f"AUDIOSTREAMID={self.AudioStreamID.text().strip()}",
            f"MANUALOPTIONS={self.ManualOptions.text().strip()}",
            f"DELETESOURCE={'Yes' if self.DeleteSource.isChecked() else 'No'}",
            f"DELETECONVERSIONLOGS={'Yes' if self.DeleteConversionLogs.isChecked() else 'No'}",
            f"ENABLEFACTORY={'Yes' if self.EnableFactory.isChecked() else 'No'}",
            f"FREEFRACTORYACTION={'Encode' if self.ActionEncode.isChecked() else 'Copy'}",
            f"ENABLEFACTORYLINKING={'Yes' if self.EnableFactoryLinking.isChecked() else 'No'}",
            f"FACTORYLINKS=",
            f"FACTORYENABLEEMAIL={'Yes' if self.EnableEmail.isChecked() else 'No'}",
            f"FACTORYEMAILNAME={self.EmailName.text().strip()}",
            f"FACTORYEMAILADDRESS={self.EmailAddress.text().strip()}",
            f"FACTORYEMAILMESSAGESTART=",
            f"FACTORYEMAILMESSAGEEND="
        ]

        filepath.write_text("\n".join(lines) + "\n")
        self.populate_factory_list()
        QMessageBox.information(self, "Factory Saved", f"Factory saved: {filename}")


#===Delete factory button with confirmation
    def delete_current_factory(self):
        filename = self.FactoryFilename.text().strip()
        if not filename:
            QMessageBox.warning(self, "Missing Filename", "No factory selected to delete.")
            return

        reply = QMessageBox.question(
            self,
            "Confirm Delete",
            f"Are you sure you want to delete '{filename}'?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        if reply != QMessageBox.StandardButton.Yes:
            return

        filepath = self.core.factory_dir / filename
        if filepath.exists():
            filepath.unlink()
            QMessageBox.information(self, "Deleted", f"Factory deleted: {filename}")
            self.populate_factory_list()
            self.FactoryFilename.clear()

#===Add a new Factory (Clears all widgets except factorylist and globals)
    def new_factory(self):
        for key in [
            "FactoryFilename", "FactoryDescription", "NotifyDirectory", "OutputDirectory",
            "OutputFileSuffix", "FTPUrl", "FTPUsername", "FTPPassword", "FTPRemotePath",
            "EmailName", "EmailAddress", "ManualOptions", "PreviewCommandLine"
        ]:
            widget = getattr(self, key, None)
            if widget:
                widget.clear()

        for key in [
            "EnableFactory", "RemoveSource", "RemoveLogs", "EnableEmail",
            "EnableFactoryLinking", "EnableFactoryGlobal", "RemoveSourceGlobal",
            "RemoveLogsGlobal", "FtpRemoveOutputGlobal", "EnableEmailGlobal",
            "FactoryLinkingGlobal"
        ]:
            widget = getattr(self, key, None)
            if widget:
                widget.setChecked(False)

        for key in [
            "FFMxProgram", "VideoCodec", "VideoWrapper", "VideoFrameRate", "VideoSize",
            "VideoBitrate", "VideoAspect", "VideoTarget", "VideoTags", "AudioCodec",
            "AudioBitrate", "AudioSampleRate", "AudioExtention", "AudioChannels",
            "FTPProgram", "Threads", "VideoPreset"
        ]:
            widget = getattr(self, key, None)
            if widget:
                widget.setCurrentIndex(-1)

        self.FactoryFilename.clear()
        self.populate_factory_list()

#===Show GPL license text
    def show_license(self):
        license_path = Path(__file__).parent / "license.txt"
        text = license_path.read_text() if license_path.exists() else "License file not found."
        dlg = LicenseDialog(text, self)
        dlg.exec()

#===Show the About box
    def show_about(self):
        dlg = AboutDialog(self)
        dlg.exec()
        
#===Queue Buttons Defs       
    def clear_conversion_queue(self):
        self.conversionQueueTable.setRowCount(0)
        self.conversionProgressBar.setValue(0)    

# End Queue Buttons Defs        
        
#===Genereate ffmpeg PREVIEW command. Now uses the proper outputfile extensions
    def on_generate_command(self):
        input_file = Path("input.filename")

        # Determine output extension from current combo boxes
        wrapper = self.VideoWrapper.currentText().strip().lstrip(".")
        audio_ext = self.AudioExtention.currentText().strip().lstrip(".")

        ext = f".{wrapper}" if wrapper else f".{audio_ext}" if audio_ext else ".out"
        output_file = Path(f"output{ext}")

#=======Simulate a "factory" dictionary from current form values
        factory = {
            "VIDEOCODECS": self.VideoCodec.currentText().strip(),
            "VIDEOWRAPPER": self.VideoWrapper.currentText().strip(),
            "VIDEOBITRATE": self.VideoBitrate.currentText().strip(),
            "VIDEOFRAMERATE": self.VideoFrameRate.currentText().strip(),
            "VIDEOSIZE": self.VideoSize.currentText().strip(),
            "ASPECT": self.VideoAspect.currentText().strip(),
            "SUBTITLECODECS": self.SubtitleCodecs.currentText().strip(),
            "AUDIOCODECS": self.AudioCodec.currentText().strip(),
            "AUDIOBITRATE": self.AudioBitrate.currentText().strip(),
            "AUDIOSAMPLERATE": self.AudioSampleRate.currentText().strip(),
            "AUDIOCHANNELS": self.AudioChannels.currentText().strip(),
            "AUDIOFILEEXTENSION": self.AudioExtention.currentText().strip(),
            "VIDEOSTREAMID": self.VideoStreamID.text().strip(),
            "GROUPPICSIZE": self.VideoGroupPicSize.text().strip(),
            "BFRAMES": self.VideoBFrames.text().strip(),
            "FRAMESTRATEGY": self.FrameStrategy.text().strip(),
            "STARTTIMEOFFSET": self.VideoStartTimeOffset.text().strip(),
            "AUDIOSTREAMID": self.AudioStreamID.text().strip(),
            "FORCEFORMAT": self.VideoForceFormat.text().strip(),
            "MANUALOPTIONS": self.ManualOptions.text().strip(),
        }

#=======Generate command using current GUI settings
        cmd_list = self.core.build_ffmpeg_command(input_file, factory)
        cmd_str = " ".join(str(arg) for arg in cmd_list)

        self.PreviewCommandLine.setText(cmd_str)



if __name__ == "__main__":
    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    app = QApplication(sys.argv)
    app.setStyle('Fusion')  #Added for Karl Compatibility
    window = FreeFactoryApp()
    window.show()
    sys.exit(app.exec())
