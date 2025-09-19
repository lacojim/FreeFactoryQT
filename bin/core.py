# core.py
# 
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
import re, shutil



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
                data[key.strip().upper()] = value.strip()
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
                    factory_data[key.strip().upper()] = value.strip()
                #else:
                #    print(f"[DEBUG] Skipping invalid line (no '='): {line.strip()}")

            #print(f"[DEBUG] Loaded factory: {factory_data}")
            return factory_data
        except Exception as e:
            print(f"[DEBUG] Exception occurred while reading factory: {e}")
            return None

# Multi-Outputs Helpers
    @staticmethod
    def _expand_multioutput_tokens(mo: str, input_path: str, output_dir: str) -> str:
        """Expand {stem} and {outdir} tokens before splitting manual output options."""
        from pathlib import Path as _Path
        import os as _os
        stem = _Path(input_path).stem
        outdir = _Path(output_dir or ".")
        outdir_str = str(outdir)
        if not outdir_str.endswith(_os.sep):
            outdir_str += _os.sep
        return (mo or "").replace("{stem}", stem).replace("{outdir}", outdir_str)

    @staticmethod
    def _truthy(v) -> bool:
        return str(v).strip().lower() in {"1", "true", "yes", "on"}
    



# This builds the ffmpeg command via cmd. 
    def build_ffmpeg_command(self, input_path, factory_data, preview=False):
        import shlex
        from pathlib import Path
        
        output_dir          = factory_data.get("OUTPUTDIRECTORY") or "."
        wrapper             = factory_data.get("VIDEOWRAPPER", "").strip().lstrip(".")
        audio_ext           = factory_data.get("AUDIOFILEEXTENSION", "").strip().lstrip(".")
        ext                 = wrapper or audio_ext or "out"

        input_stem          = Path(input_path).stem
        if preview:
            output_filename = f"output.{ext}"
        else:
            output_filename = f"{input_stem}.{ext}"

        output_path         = Path(output_dir) / output_filename

        video_codec         = factory_data.get("VIDEOCODECS", "").strip()
        video_flags         = factory_data.get("FLAGS", "").strip()
        video_flags2        = factory_data.get("FLAGS2", "").strip()
        video_bitrate       = factory_data.get("VIDEOBITRATE", "").strip()
        video_profile       = factory_data.get("VIDEOPROFILE", "").strip()
        video_profile_level = factory_data.get("VIDEOPROFILELEVEL", "").strip()
        size                = factory_data.get("VIDEOSIZE", "").strip()
        video_preset        = factory_data.get("VIDEOPRESET", "").strip()
        subtitle            = factory_data.get("SUBTITLECODECS", "").strip()
        removea53cc         = factory_data.get("REMOVEA53CC", "").strip()
        audio_codec         = factory_data.get("AUDIOCODECS", "").strip()
        audio_bitrate       = factory_data.get("AUDIOBITRATE", "").strip()
        sample_rate         = factory_data.get("AUDIOSAMPLERATE", "").strip()
        audio_channels      = factory_data.get("AUDIOCHANNELS", "").strip()
        manual_output       = factory_data.get("MANUALOPTIONSOUTPUT", "").strip()
        manual_input        = factory_data.get("MANUALOPTIONSINPUT", "").strip()
        bframes             = factory_data.get("BFRAMES", "").strip()
        frame_strategy      = factory_data.get("FRAMESTRATEGY", "").strip()
        gop_size            = factory_data.get("GROUPPICSIZE", "").strip()
        video_format        = factory_data.get("VIDEOFORMAT", "").strip()
        pix_format          = factory_data.get("VIDEOPIXFORMAT", "").strip()
        start_offset        = factory_data.get("STARTTIMEOFFSET", "").strip()
        encode_length       = factory_data.get("ENCODELENGTH", "").strip()
        force_format        = factory_data.get("FORCEFORMAT", "").strip()
        video_stream_id     = factory_data.get("VIDEOSTREAMID", "").strip()
        audio_stream_id     = factory_data.get("AUDIOSTREAMID", "").strip()
        vf                  = (factory_data.get("VIDEOFILTERS")  or "").strip()
        af                  = (factory_data.get("AUDIOFILTERS")  or "").strip()
        disablevideo        = (factory_data.get("DISABLEVIDEO")  or "").strip()
        disableaudio        = (factory_data.get("DISABLEAUDIO")  or "").strip()
        disablesubs         = (factory_data.get("DISABLESUBS")  or "").strip()
        disabledata         = (factory_data.get("DISABLEDATA")  or "").strip()
        
        # Video Advanced Options
        adv_colorspace      = (factory_data.get("COLORSPACE")  or "").strip()
        adv_colorrange      = (factory_data.get("COLORRANGE")  or "").strip()
        adv_colortrc        = (factory_data.get("COLORTRC")  or "").strip()
        adv_samplelocation  = (factory_data.get("COLORSAMPLELOCATION")  or "").strip()
        adv_colorprimarties = (factory_data.get("COLORPRIMARIES")  or "").strip()
        adv_altscan         = (factory_data.get("ALTERNATESCAN")  or "").strip()            #CHECK
        adv_nonlinearquant  = (factory_data.get("NONLINEARQUANT")  or "").strip()           #CHECK
        adv_signalstd       = (factory_data.get("SIGNALSTANDARD")  or "").strip()
        adv_seqdispext      = (factory_data.get("SEQDISPEXT")  or "").strip()
        adv_fieldorder      = (factory_data.get("FIELDORDER")  or "").strip()
        adv_intravlc        = (factory_data.get("INTRAVLC")  or "").strip()        
        adv_dc              = (factory_data.get("DC")  or "").strip()
        adv_qmin            = (factory_data.get("QMIN")  or "").strip()
        adv_qmax            = (factory_data.get("QMAX")  or "").strip()
        adv_rcinitoccup     = (factory_data.get("RCINITOCCUPANCY")  or "").strip()
        adv_bufsize         = (factory_data.get("BUFSIZE")  or "").strip()

        
        # --- Build base, add manual *input* flags BEFORE -i ---
        cmd                 = ["ffmpeg", "-hide_banner", "-y"]
        if manual_input:
            cmd += shlex.split(manual_input)
        cmd += ["-i", str(input_path)]

        #=======Disable Select Streams
        disablevideo_flag    = str(disablevideo).strip().lower() in ("1", "true", "yes") # Ignore unless True, yes or 1. 
        if disablevideo_flag:
            cmd += ["-vn"]

        disableaudio_flag    = str(disableaudio).strip().lower() in ("1", "true", "yes")
        if disableaudio_flag:
            cmd += ["-an"]
        
        disablesubs_flag    = str(disablesubs).strip().lower() in ("1", "true", "yes")
        if disablesubs_flag:
            cmd += ["-sn"]

        disabledata_flag    = str(disabledata).strip().lower() in ("1", "true", "yes")            
        if disabledata_flag:
            cmd += ["-dn"]

        #=======Video encoding
        if video_codec:
            cmd += ["-c:v", video_codec]

        if video_flags:
            cmd += ["-flags", video_flags]

        if video_flags2:
            cmd += ["-flags2", video_flags2]

        if video_bitrate:
            cmd += ["-b:v", video_bitrate]

            # MATCHMINMAXBITRATE support
            match_minmax = factory_data.get("MATCHMINMAXBITRATE", "False").strip().lower() == "true"
            if match_minmax:
                # Clean up any existing -minrate/-maxrate from manual options (just in case)
                def strip_flag(flagname):
                    try:
                        while flagname in cmd:
                            i = cmd.index(flagname)
                            del cmd[i:i+2]
                    except:
                        pass
                strip_flag("-minrate")
                strip_flag("-maxrate")
                cmd += ["-minrate", video_bitrate, "-maxrate", video_bitrate]

# Insert Advanced Video Here: WORK IN PROGRESS
        # Chroma settings
        if adv_colorspace:
            cmd += ["-colorspace", adv_colorspace]
        if adv_colorrange:
            cmd += ["-color_range", adv_colorrange]
        if adv_colortrc:
            cmd += ["-color_trc", adv_colortrc]
        if adv_samplelocation:
            cmd += ["-chroma_sample_location", adv_samplelocation]
        if adv_colorprimarties:
            cmd += ["-color_primaries", adv_colorprimarties]
        # Standards and Fields
        adv_altscan_flag    = str(adv_altscan).strip().lower() in ("1", "true", "yes")
        if adv_altscan_flag:
            cmd += ["-alternate_scan", "1"]
        adv_nonlinearquant_flag    = str(adv_nonlinearquant).strip().lower() in ("1", "true", "yes")
        if adv_nonlinearquant_flag:
            cmd += ["-non_linear_quant", "1"]

        if adv_signalstd:
            cmd += ["-signal_standard", adv_signalstd]
        if adv_seqdispext:
            cmd += ["-seq_disp_ext", adv_seqdispext]
        if adv_fieldorder:
            cmd += ["-field_order", adv_fieldorder]

        adv_intravlc_flag    = str(adv_intravlc).strip().lower() in ("1", "true", "yes")
        if adv_intravlc_flag:
            cmd += ["-intra_vlc", "1"]

        if adv_rcinitoccup:
            cmd += ["-rc_init_occupancy", adv_rcinitoccup]
            
        if adv_bufsize:
            cmd += ["-bufsize", adv_bufsize]
            
        if adv_dc:
            cmd += ["-dc", str(adv_dc)]

        if adv_qmin:
            cmd += ["-qmin", str(adv_qmin)]

        if adv_qmax:
            cmd += ["-qmax", str(adv_qmax)]
            
        # Optional guardrail: qmin should not exceed qmax
        try:
            if adv_qmin and adv_qmax and int(adv_qmin) > int(adv_qmax):
                # clamp or raise warning — here we clamp
                cmd[-1] = adv_qmin  # replace qmax value
        except ValueError:
            pass




# End Advanced Video:

        if video_profile:
            cmd += ["-profile:v", video_profile]
        if video_profile_level:
            cmd += ["-level:v", video_profile_level]
        
        
        if video_preset:
            cmd += ["-preset:v", video_preset]
        if gop_size:
            cmd += ["-g", gop_size]
        if bframes:
            cmd += ["-bf", bframes]
        if frame_strategy:
            cmd += ["-b_strategy", frame_strategy]
        if video_format:
            cmd += ["-video_format", video_format]
        
            
        # --- VIDEO filters / size
        if vf and not vf.endswith("="):
            cmd += ["-vf", vf]    
        # Only add -s if user didn't already scale in -vf
        if size and not self._has_scale(vf):
            cmd += ["-s", size]          
        if pix_format:
            cmd += ["-pix_fmt", pix_format]

            
        #=======Subtitles
        # normalize the flag (handles None, "false", "False", etc.)
        removea53cc_flag    = str(removea53cc).strip().lower() in ("1", "true", "yes")
        
        if subtitle:
            cmd += ["-c:s", subtitle]
        if removea53cc_flag and video_codec not in ("copy", "", None):
            cmd += ["-a53cc", "0"]

        #=======Audio encoding
        if audio_codec:
            cmd += ["-c:a", audio_codec]
        if audio_bitrate:
            cmd += ["-b:a", audio_bitrate]
        if sample_rate:
            cmd += ["-ar", sample_rate]
        if audio_channels:
            cmd += ["-ac", audio_channels]
        if af and not af.endswith("="):
            cmd += ["-af", af]
        #if audio_tags:
        #    cmd += ["-tags:a", audio_tags]
        
        #=======Stream mapping
        if video_stream_id:
            cmd += ["-streamid:v", video_stream_id]
        if audio_stream_id:
            cmd += ["-streamid:a", audio_stream_id]

        #=======Output seeking
        if encode_length:
            cmd += ["-t", encode_length]
        if start_offset:
            cmd += ["-ss", start_offset]
            print("DEBUG force_format raw value:", repr(force_format))

        #======= MULTI-OUTPUT + Manual options
        multi = self._truthy(factory_data.get("MULTIOUTPUT", "False"))

        if manual_output:
            manual_output = self._expand_multioutput_tokens(
                manual_output,
                str(input_path),
                output_dir
            )
            cmd += shlex.split(manual_output)

        if not multi:
            if force_format:
                cmd += ["-f", force_format]
            cmd.append(output_path.as_posix())
        else:
            # Safety rail: require explicit destinations in MANUALOPTIONSOUTPUT
            if not (manual_output and manual_output.strip()):
                raise ValueError("MULTIOUTPUT=True but MANUALOPTIONSOUTPUT is empty; no outputs would be produced.")

        #print("DEBUG final cmd:", cmd)
        return cmd

#======

    @staticmethod
    def _has_scale(vf: str) -> bool:
        """Return True if the -vf chain already contains a scaler."""
        if not vf:
            return False
        s = "".join(vf.split()).lower()  # strip whitespace
        # cover common scaler variants so we don't double-scale
        return any(tag in s for tag in (
            "scale=",        # classic software scaler
            "zscale=",       # zimg
            "scale_cuda=",   # CUDA
            "scale_npp=",    # NVENC/NPP
            "scale_vaapi=",  # VAAPI
            "scale_qsv=",    # QuickSync
            "scale2ref=",
        ))

    @staticmethod
    def _looks_wh(size: str) -> bool:
        """Return True if size looks like WIDTHxHEIGHT (e.g., 1920x1080)."""
        if not size:
            return False
        size = size.strip().lower()
        # very light validation; adjust if you allow things like 1920x1080:flags=...
        import re
        return re.fullmatch(r"\d{2,5}x\d{2,5}", size) is not None

#===Build streaming flags
    def build_streaming_flags(self, factory_data):
        flags = []

        video_codec     = factory_data.get("VIDEOCODECS", "").strip()
        video_flags     = factory_data.get("FLAGS", "").strip()
        video_flags2    = factory_data.get("FLAGS2", "").strip()
        audio_codec     = factory_data.get("AUDIOCODECS", "").strip()
        preset          = factory_data.get("VIDEOPRESET", "").strip()
        video_bitrate   = factory_data.get("VIDEOBITRATE", "").strip()
        audio_bitrate   = factory_data.get("AUDIOBITRATE", "").strip()
        
        vf_string       = (factory_data.get("VIDEOFILTERS","") or "").strip()
        size            = (factory_data.get("VIDEOSIZE","") or "").strip()
        af_string       = (factory_data.get("AUDIOFILTERS","") or "").strip()
        
        pix_format      = factory_data.get("VIDEOPIXFORMAT", "").strip()

        if video_codec:
            flags += ["-c:v", video_codec]
        if video_flags:
            flags += ["-flags", video_flags]
        if video_flags2:
            flags += ["-flags2", video_flags2]
        if video_bitrate:
            flags += ["-b:v", video_bitrate]
        if preset:
            flags += ["-preset", preset]
        if audio_codec:
            flags += ["-c:a", audio_codec]
        if audio_bitrate:
            flags += ["-b:a", audio_bitrate]
        if vf_string and not vf_string.endswith("="):
            flags += ["-vf", vf_string]
        if size and not self._has_scale(vf_string):
            flags += ["-s", size]
        if af_string and not af_string.endswith("="):
            flags += ["-af", af_string]
        if pix_format:
            flags += ["-pix_fmt", pix_format]

        # Optional: add more streaming-friendly flags like -tune zerolatency
        return flags
    

# ============================
#      Build Streaming Command
# ============================
    def build_streaming_command(
        self,
        factory_data: dict,
        *,
        video_input: str = "",
        audio_input: str = "",
        video_input_format: str = "",
        audio_input_format: str = "",
        output_url: str = "",
        re_for_file_inputs=False,
    ) -> list[str]:
        """
        Build the ffmpeg command for streaming.

        Ordering:
        - If MANUALOPTIONSINPUT contains any -i, treat it as verbatim input graph and paste as-is.
        - Else: treat MANUALOPTIONSINPUT (if present) as *pre-video* options, then inject UI inputs:
                [pre-video opts]  -i <video>   [ -f <audio_fmt> ] -i <audio>
        - Append widget-driven flags via build_streaming_flags(factory_data).
        - Append MANUALOPTIONS (post-input overrides).
        - Append -f FORCEFORMAT (if any), then the output_url.
        """
        import shlex

        if not output_url:
            raise ValueError("Missing output_url for streaming command.")

        # -------------------- config / toggles --------------------
        manual_input    = (factory_data.get("MANUALOPTIONSINPUT", "") or "").strip()
        manual_output   = (factory_data.get("MANUALOPTIONSOUTPUT", "") or "").strip()
        force_format    = (factory_data.get("FORCEFORMAT", "") or "").strip()

        # New widgets / fields
        include_tqs     = (factory_data.get("INCLUDETQS", "True") or "True").strip().lower() == "true"
        tqs_size        = (factory_data.get("TQSSIZE", "512")    or "512").strip() or "512"
        low_latency     = (factory_data.get("LOWLATENCYINPUT", "False") or "False").strip().lower() == "true"
        auto_map_av     = (factory_data.get("AUTOMAPAV", "False")        or "False").strip().lower() == "true"
        factory_name    = (factory_data.get("STREAMINGFACTORYNAME", "")  or "").strip()

        cmd = ["ffmpeg", "-hide_banner", "-y"]

        # Low-latency global hint (safe on live inputs; harmless on files)
        if low_latency:
            # keep this minimalist; avoids big buffering without breaking demuxers
            cmd += ["-fflags", "nobuffer"]

        # -------------------- INPUTS --------------------
        tokens = shlex.split(manual_input) if manual_input else []
        has_i  = any(tok == "-i" for tok in tokens)

        def add_input(fmt: str, src: str, pre_first: bool):
            if not src:
                return

            fmt_norm = (fmt or "").strip().lower()
            is_filelike = fmt_norm in ("file", "", "concat")  # treat concat like file

            # Only put pre-video manual opts before capture inputs, not file/concat
            if pre_first and not is_filelike:
                cmd.extend(tokens)

            # For capture formats include -f
            if not is_filelike and fmt_norm:
                cmd.extend(["-f", fmt_norm])

            # Thread queue only for capture inputs
            if include_tqs and tqs_size and not is_filelike:
                cmd.extend(["-thread_queue_size", str(tqs_size)])

            # Throttle file-like inputs (-re) right before their -i
            if is_filelike and re_for_file_inputs:
                cmd.append("-re")

            cmd.extend(["-i", src])



        if manual_input and has_i:
            cmd += tokens
        else:
            # Only treat ManualOptionsInput as pre-video when the *video* is capture (not "File")
            #pre_before_video = bool(video_input) and ((video_input_format or "").strip().lower() != "file")
            pre_before_video = bool(video_input) and (
                (video_input_format or "").strip().lower() not in ("file", "", "concat")

            )

            # VIDEO input
            add_input(video_input_format, video_input, pre_before_video)

            # AUDIO input
            add_input(audio_input_format, audio_input, pre_first=False)

        # ...below unchanged...


        # -------------------- FLAGS FROM WIDGETS --------------------
        cmd += self.build_streaming_flags(factory_data)

        # -------------------- AUTO MAP (optional) --------------------
        if auto_map_av and not any(tok == "-map" for tok in cmd):
            # Count inputs by number of -i tokens added
            num_inputs = sum(1 for t in cmd if t == "-i")
            if num_inputs >= 2:
                cmd += ["-map", "0:v:0", "-map", "1:a:0"]
            elif num_inputs == 1:
                # Map video from the single input to be explicit (helps some muxers)
                cmd += ["-map", "0:v:0"]

        # -------------------- MANUAL (post-input overrides) --------------------
        if manual_output:
            cmd += shlex.split(manual_output)

        # Optional: tag the factory name as metadata if provided (harmless for FLV/TS)
        if factory_name:
            cmd += ["-metadata", f"comment=Streamed by {factory_name}"]

        # -------------------- MUXER + DESTINATION --------------------
        if force_format:
            cmd += ["-f", force_format]
        cmd.append(output_url)

        return cmd



    # ============================
    #      Build Recording Command
    # ============================    
    def build_recording_command(
        self,
        factory_data: dict,
        *,
        video_input: str = "",          # e.g. ":0.0+0,0" (desktop) or "/path/to/file" or "rtmp://..."
        audio_input: str = "",          # e.g. "default" (Pulse), or "" for none
        video_input_format: str = "",   # "x11grab", "file", "gdigrab" (future Windows), etc.
        audio_input_format: str = "",   # "pulse", "alsa", "dshow" (future Windows), etc.
        output_path: str = "",          # full path resolved by UI (folder + filename template)
        re_for_file_inputs: bool = True
    ) -> list[str]:
        """
        Build a file-recording ffmpeg command using the same flags as streaming/encode.
        Input graph handling mirrors build_streaming_command(...), but destination is a file.
        """
        import shlex
        if not output_path:
            raise ValueError("Missing output_path for recording.")

        manual_input  = (factory_data.get("MANUALOPTIONSINPUT", "") or "").strip()
        manual_output = (factory_data.get("MANUALOPTIONSOUTPUT", "") or "").strip()
        force_format  = (factory_data.get("FORCEFORMAT", "") or "").strip()

        # toggles also used in streaming:
        include_tqs = (factory_data.get("INCLUDETQS", "True") or "True").strip().lower() == "true"
        tqs_size    = (factory_data.get("TQSSIZE", "512")    or "512").strip() or "512"
        low_latency = (factory_data.get("LOWLATENCYINPUT", "False") or "False").strip().lower() == "true"

        cmd = ["ffmpeg", "-hide_banner", "-y"]
        if low_latency:
            cmd += ["-fflags", "nobuffer"]

        tokens = shlex.split(manual_input) if manual_input else []
        has_i  = any(tok == "-i" for tok in tokens)

        def add_input(fmt: str, src: str, pre_first: bool):
            # nonlocal cmd  # optional safety if you ever reintroduce +=
            if not src:
                return

            fmt_norm = (fmt or "").strip().lower()
            is_filelike = fmt_norm in ("file", "", "concat")

            if pre_first and not is_filelike:
                cmd.extend(tokens)

            if not is_filelike and fmt_norm:
                cmd.extend(["-f", fmt_norm])

            if include_tqs and tqs_size and not is_filelike:
                cmd.extend(["-thread_queue_size", str(tqs_size)])

            if is_filelike and re_for_file_inputs:
                cmd.append("-re")

            cmd.extend(["-i", src])


        if manual_input and has_i:
            cmd += tokens
        else:
            pre_before_video = bool(video_input) and ((video_input_format or "").strip().lower() not in ("file", "", "concat"))
            add_input(video_input_format, video_input, pre_before_video)
            add_input(audio_input_format, audio_input, pre_first=False)

        # Reuse your existing flag builder (same knobs as streaming/encodes)
        cmd += self.build_streaming_flags(factory_data)

        # Post-input manual overrides
        if manual_output:
            cmd += shlex.split(manual_output)

        # Muxer/format and destination
        if force_format:
            cmd += ["-f", force_format]
        cmd.append(str(output_path))
        return cmd


