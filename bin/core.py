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



class FreeFactoryCore:
    def __init__(self):
        self.factory_dir = Path("/opt/FreeFactory/Factories")
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

    def load_factory(self, name):
        for file_path in self.factory_files:
            if Path(file_path).stem == name:
                with open(file_path, "r") as f:
                    lines = f.readlines()
                return self.parse_factory_file(lines)
        return None


# Added to support Drag and Drop Encoding directly from the UI.

    def build_ffmpeg_command(self, input_path, factory_data):
        output_dir = factory_data.get("OUTPUTDIRECTORY") or "."
        suffix = factory_data.get("OUTPUTFILESUFFIX", "")
        wrapper = factory_data.get("VIDEOWRAPPER") or factory_data.get("AUDIOFILEEXTENSION") or ".mp4"
        wrapper = wrapper.lstrip(".")
        codec = factory_data.get("VIDEOCODECS", "").strip()
        size = factory_data.get("VIDEOSIZE", "").strip()
        subtitle = factory_data.get("SUBTITLECODECS", "").strip()
        audio = factory_data.get("AUDIOCODECS", "").strip()
        manual = factory_data.get("MANUALOPTIONS", "").strip()
        
        video_stream_id = factory_data.get("VIDEOSTREAMID", "").strip()
        audio_stream_id = factory_data.get("AUDIOSTREAMID", "").strip()

        input_stem = Path(input_path).stem
        output_filename = f"{input_stem}{suffix}.{wrapper}"
        output_path = Path(output_dir) / output_filename

        cmd = ["ffmpeg", "-hide_banner", "-y", "-i", input_path]

        # Only add video codec if explicitly defined
        if codec:
            cmd += ["-c:v", codec]
        if size and codec:
            cmd += ["-s", size]
        if subtitle:
            cmd += ["-c:s", subtitle]
        if audio:
            cmd += ["-c:a", audio]


        if video_stream_id:
            cmd += ["-streamid", f"v:{video_stream_id}"]
        if audio_stream_id:
            cmd += ["-streamid", f"a:{audio_stream_id}"]



        # Extra manual options
        if manual:
            cmd += shlex.split(manual)

        cmd.append(output_path.as_posix())

        print("DEBUG final cmd:", cmd)
        return cmd
