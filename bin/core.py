# core.py
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

import os
import subprocess
import shlex
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, QThread




#=======For Drop Queue
class FFmpegWorker(QThread):
    result = pyqtSignal(int, str, str)  # returncode, stdout, stderr

    def __init__(self, cmd):
        super().__init__()
        self.cmd = cmd
        self.error = None

    def run(self):
        import subprocess
        process = subprocess.run(self.cmd, capture_output=True, text=True)
        self.result.emit(process.returncode, process.stdout, process.stderr)


#=======For Drop Zone (Main Tab FFmpegWorkerZone)
class FFmpegWorkerZone(QObject):
    finished = pyqtSignal(str)
    error = pyqtSignal(str)

    def __init__(self, cmd):
        super().__init__()
        self.cmd = cmd

    def run(self):
        try:
            process = subprocess.run(self.cmd, capture_output=True, text=True)
            if process.returncode == 0:
                self.finished.emit("✅ Conversion complete.")
            else:
                self.error.emit(f"❌ Error:\n{process.stderr}")
        except Exception as e:
            self.error.emit(f"⚠️ Exception: {str(e)}")
            
#========StreamWorker for Streaming Tab
class StreamWorker(QThread):
    output = pyqtSignal(str)
    finished = pyqtSignal()
    error = pyqtSignal(str)

    def __init__(self, cmd):
        super().__init__()
        self.cmd = cmd
        self.process = None
        self._stop_requested = False

    def run(self):
        try:
            self.process = subprocess.Popen(
                self.cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1
            )

            for line in self.process.stdout:
                if self._stop_requested:
                    break
                self.output.emit(line.strip())

            self.process.wait()
            self.finished.emit()
        except Exception as e:
            self.error.emit(str(e))

    def stop(self):
        self._stop_requested = True
        if self.process:
            self.process.terminate()


class FreeFactoryCore:
    def __init__(self, config):
        self.factory_dir = Path(config.get("FactoryLocation"))
       #self.factory_dir = Path("/opt/FreeFactory/Factories") # Replaced by line above.
        self.factory_files = []
        self.active_factory = None
        self.output_directory = Path.home() / "FreeFactory-Output"
        self.command_line = ""

        self.init_variables()
        
        
    def parse_factory_file(self, lines):
        data = {}
        for line in lines:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, value = line.split("=", 1)
                data[key.strip()] = value.strip()
        return data    

    def init_variables(self):
        self.factory_dir.mkdir(parents=True, exist_ok=True)
        self.output_directory.mkdir(exist_ok=True)
        self.factory_files = list(self.factory_dir.glob("*"))
       
    def reload_factory_files(self):
            self.factory_files = list(self.factory_dir.glob("*"))        

    def save_factory_file(self, filename, content):
        path = self.factory_dir / filename
        with open(path, "w") as f:
            f.write(content)
        if path not in self.factory_files:
            self.factory_files.append(path)

    def delete_factory_file(self, filename):
        path = self.factory_dir / filename
        if path.exists():
            path.unlink()
            self.factory_files.remove(path)
        
        
    def view_command_line(self, input_file, options):
        # Construct an ffmpeg command or similar based on options
        output_file = self.output_directory / f"converted_{input_file.name}"
        cmd = [
            "ffmpeg",
            "-i", str(input_file),
            *options,
            str(output_file)
        ]
        self.command_line = " ".join(cmd)
        return self.command_line

    def run_command(self):
        if self.command_line:
            subprocess.run(self.command_line, shell=True)
        else:
            raise RuntimeError("No command line to run.")
        
        pass
    
    
    def load_factory(self, factory_path):
        #print(f"[DEBUG] Attempting to load factory: {factory_path}")
        if not factory_path.exists():
            print("[DEBUG] Factory file does not exist.")
            return None

        try:
            with open(factory_path, "r") as f:
                lines = f.readlines()

            factory_data = {}
            for line in lines:
                if "=" in line:
                    key, value = line.strip().split("=", 1)
                    factory_data[key.strip()] = value.strip()
                #else:
                #    print(f"[DEBUG] Skipping invalid line (no '='): {line.strip()}")

            #print(f"[DEBUG] Loaded factory: {factory_data}")
            return factory_data
        except Exception as e:
            print(f"[DEBUG] Exception occurred while reading factory: {e}")
            return None

 
    

#===Fixes loading default factory whenever a directory selector is used for output directory.
    def select_output_directory(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Output Directory")
        if directory:
            # Prevent unwanted list signal side-effects
            self.listFactoryFiles.blockSignals(True)
            self.OutputDirectory.setText(directory)
            self.listFactoryFiles.blockSignals(False)



# Added to support Drag and Drop Encoding directly from the UI.
# This builds the ffmpeg command via cmd. 
    def build_ffmpeg_command(self, input_path, factory_data, preview=False):
        import shlex
        from pathlib import Path

        output_dir = factory_data.get("OUTPUTDIRECTORY") or "."
        wrapper = factory_data.get("VIDEOWRAPPER", "").strip().lstrip(".")
        audio_ext = factory_data.get("AUDIOFILEEXTENSION", "").strip().lstrip(".")
        ext = wrapper or audio_ext or "out"

        input_stem = Path(input_path).stem
        if preview:
            output_filename = f"output.{ext}"
        else:
            output_filename = f"{input_stem}.{ext}"

        output_path = Path(output_dir) / output_filename

        encode_length = factory_data.get("ENCODELENGTH", "").strip()
        video_codec = factory_data.get("VIDEOCODECS", "").strip()
        video_bitrate = factory_data.get("VIDEOBITRATE", "").strip()

        video_profile = factory_data.get("VIDEOPROFILE", "").strip()
        video_profile_level = factory_data.get("VIDEOPROFILELEVEL", "").strip()
      
        size = factory_data.get("VIDEOSIZE", "").strip()
        subtitle = factory_data.get("SUBTITLECODECS", "").strip()
        audio_codec = factory_data.get("AUDIOCODECS", "").strip()
        audio_bitrate = factory_data.get("AUDIOBITRATE", "").strip()
        sample_rate = factory_data.get("AUDIOSAMPLERATE", "").strip()
        audio_channels = factory_data.get("AUDIOCHANNELS", "").strip()
        manual = factory_data.get("MANUALOPTIONS", "").strip()
        bframes = factory_data.get("BFRAMES", "").strip()
        frame_strategy = factory_data.get("FRAMESTRATEGY", "").strip()
        gop_size = factory_data.get("GROUPPICSIZE", "").strip()
        pix_format = factory_data.get("VIDEOPIXFORMAT", "").strip()
        start_offset = factory_data.get("STARTTIMEOFFSET", "").strip()
        force_format = factory_data.get("FORCEFORMAT", "").strip()

        video_stream_id = factory_data.get("VIDEOSTREAMID", "").strip()
        audio_stream_id = factory_data.get("AUDIOSTREAMID", "").strip()
        

        cmd = ["ffmpeg", "-hide_banner", "-y", "-i", str(input_path)]

#=======Video encoding
        if video_codec:
            cmd += ["-c:v", video_codec]
        if video_bitrate:
            cmd += ["-b:v", video_bitrate]
        if video_profile:
            cmd += ["-profile:v", video_profile]
        if video_profile_level:
            cmd += ["-level:v", video_profile_level]
        if gop_size:
            cmd += ["-g", gop_size]
        if bframes:
            cmd += ["-bf", bframes]
        if frame_strategy:
            cmd += ["-b_strategy", frame_strategy]
        if pix_format:
            cmd += ["-pix_fmt", pix_format]
        if size and video_codec:
            cmd += ["-s", size]
        #if video_tags:
        #    cmd += ["-tag:v", video_tags]
            
#=======Subtitles
        if subtitle:
            cmd += ["-c:s", subtitle]

#=======Audio encoding
        if audio_codec:
            cmd += ["-c:a", audio_codec]
        if audio_bitrate:
            cmd += ["-b:a", audio_bitrate]
        if sample_rate:
            cmd += ["-ar", sample_rate]
        if audio_channels:
            cmd += ["-ac", audio_channels]
        #if audio_tags:
        #    cmd += ["-tags:a", audio_tags]
#=======Stream mapping
        if video_stream_id:
            cmd += ["-streamid", f"v:{video_stream_id}"]
        if audio_stream_id:
            cmd += ["-streamid", f"a:{audio_stream_id}"]

#=======Output seeking and format
        if encode_length:
            cmd += ["-t", encode_length]
        if start_offset:
            cmd += ["-ss", start_offset]
            print("DEBUG force_format raw value:", repr(force_format))
        if force_format:
            cmd += ["-f", force_format]

#=======Manual options (always last before output)
        if manual:
            cmd += shlex.split(manual)

        cmd.append(output_path.as_posix())

        print("DEBUG final cmd:", cmd)
        return cmd
#======

#===Build streaming flags
    def build_streaming_flags(self, factory_data):
        flags = []

        video_codec = factory_data.get("VIDEOCODECS", "").strip()
        audio_codec = factory_data.get("AUDIOCODECS", "").strip()
        video_bitrate = factory_data.get("VIDEOBITRATE", "").strip()
        audio_bitrate = factory_data.get("AUDIOBITRATE", "").strip()
        preset = factory_data.get("VIDEOPRESET", "").strip()

        if video_codec:
            flags += ["-c:v", video_codec]
        if video_bitrate:
            flags += ["-b:v", video_bitrate]
        if preset:
            flags += ["-preset", preset]
        if audio_codec:
            flags += ["-c:a", audio_codec]
        if audio_bitrate:
            flags += ["-b:a", audio_bitrate]

        # Optional: add more streaming-friendly flags like -tune zerolatency
        return flags







