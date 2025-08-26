![image](https://github.com/user-attachments/assets/9cca7be8-736b-4768-8cd6-79cbd008605a)
# FreeFactoryQT
<img width="1101" height="730" alt="image" src="https://github.com/user-attachments/assets/4caa7b05-6704-4566-8de6-ae1d6780f13d" />

> ⚠️ **Note:** Changelogs are now located at the bottom of this README.

---

## 🎬 What is FreeFactoryQT?

**FreeFactoryQT** is a powerful, user-friendly media conversion system designed for both casual users and broadcast professionals. Originally developed for in-house use at a television station by a broadcast engineer with 40 years of experience, it has evolved from a set of BASH scripts into a full-featured Python3 application with a Qt6 interface.

Taking full advantage of the powerful [FFmpeg](https://ffmpeg.org) backend, FreeFactoryQT simplifies complex encoding workflows into reusable, sharable *Factories*. While FFmpeg is incredibly powerful, its syntax can be intimidating — FreeFactoryQT makes it accessible without sacrificing advanced capability.

---

## 🚀 Key Features

- Design and save reusable conversion workflows as **Factories**
- GUI-based direct conversion of single or batch files
- Supports drag-and-drop and watched folders
- Clean separation between UI (FreeFactoryQT) and background service (`FreeFactoryConversion.tcl`)
- Fully compatible with FFmpeg — **FFmbc support has been deprecated**

FreeFactory makes sharing encoding setups easy: import a Factory, update the Output and Notify directories, and you're ready to go.

> 📦 Factories are portable and easy to exchange. Only minor path edits are usually required.

---

## 🖥️ Installation

**Requirements:**
- Python 3
- PyQt6
- `inotifywait` (only for background service)
- `tclsh` (only for background service)

**Steps:**
1. Create the following directory:  
   ```bash
   sudo mkdir -p /opt/FreeFactory
   ```
2. Extract the `.zip` archive contents into `/opt/FreeFactory/`
3. Launch the application:  
   ```bash
   cd /opt/FreeFactory/bin
   python3 main.py
   ```
4. *(Optional)* Create a desktop launcher for convenience

---

## 📸 Screenshots

Drag-and-drop and batch conversion make FreeFactoryQT intuitive:

<img width="1100" height="728" alt="image" src="https://github.com/user-attachments/assets/15e3e851-86e0-4740-b4ae-b05916e5e6a1" />


Preset-driven FFmpeg configurations for power users and broadcasters:

<img width="1101" height="730" alt="image" src="https://github.com/user-attachments/assets/4caa7b05-6704-4566-8de6-ae1d6780f13d" />

Fully editable factories with support for complex options:

<img width="1099" height="749" alt="livestreamandrecordmgr" src="https://github.com/user-attachments/assets/c85bbc20-8b0d-4ef6-8dc2-9b517c6725b2" />



---

## ⚙️ Setting Up the FreeFactory Service (Optional)

> ⚠️ Until ported to Python, this service requires **Tcl** and **inotifywait**.

To install or manage the background notify service:
```bash
./setup-notifyservice.sh
```

Example output:
```
🔧 FreeFactory Notify Service Setup
----------------------------------
🔍 Checking if the service is currently running...
✅ Service is not currently running.

📂 Installed in USER mode

Choose an action:
1) Install/enable in USER mode
2) Install/enable in SYSTEM-WIDE mode (requires sudo)
3) Uninstall from USER mode
4) Uninstall from SYSTEM-WIDE mode
5) Quit
Selection:
```

Then activate it:
```bash
systemctl --user start freefactory-notify
systemctl --user enable freefactory-notify
```

This can also be started/stopped from within the FreeFactoryQT interface.

<img width="1102" height="750" alt="globalandservicecontrols" src="https://github.com/user-attachments/assets/7fcf886b-e854-48c4-8b35-cf77f4621d24" />

---

## 🚀 Advanced Help Tab which utilizes the built-in help of your installed FFmpeg version

<img width="1261" height="752" alt="ffmpeghelp" src="https://github.com/user-attachments/assets/dc514017-a24a-4854-b779-09a91c728c27" />

---

## ✍ Example: Advanced Manual FFmpeg Options

Even highly specialized commands can be stored in a Factory. For example:

```bash
-c:v mpeg2video -pix_fmt yuv422p -aspect 16:9 -intra_vlc 1 -b:v 50000000 -minrate 50000000 -maxrate 50000000 -bufsize 17825792 -rc_init_occupancy 17825792 -bf 2 -non_linear_quant 1 -color_primaries bt709 -color_trc bt709 -colorspace bt709 -seq_disp_ext 1 -video_format component -color_range 1 -chroma_sample_location topleft -signal_standard 4 -dc 8 -qmin 5 -qmax 23 -g 12 -field_order tt -top 1 -flags +ildct+ilme -alternate_scan 1 -c:a pcm_s24le -ar:a 48000
```

These would be stored under the `Manual Options` field in your Factory, and saved for future use.
=======
## ✍ Example: Advanced Manual Input FFmpeg Options

Even highly specialized input commands can be stored in a Factory. For example:

```bash
-thread_queue_size 512 -f x11grab -framerate 60 -video_size 1920x1080 -i :0.0+1920,2160 -thread_queue_size 512 -f pulse -i default
```

These would be stored under the `Manual Input Ops` field in your Factory, and saved for future use.

## ✍ Example: Advanced Manual Output FFmpeg Options

Highly specialized output commands can be stored in a Factory too. For example:

```bash
-intra_vlc 1 -bufsize 17825792 -rc_init_occupancy 17825792 -bf 2 -non_linear_quant 1 -color_primaries bt709 -color_trc bt709 -colorspace bt709 -seq_disp_ext 1 -video_format component -color_range 1 -chroma_sample_location topleft -signal_standard 4 -dc 8 -qmin 5 -qmax 23 -g 12 -field_order tt -top 1 -flags +ildct+ilme -alternate_scan 1
```

These would be stored under the `Manual Output Ops` field in your Factory, and saved for future use.

---


## 🆕 Changelog

=======
### 📅 New – 2025-08-23

Notify subsystem (runner + notifier)

✨ Added support for multiple NotifyFolders in .freefactoryrc (semicolon-separated).
The runner generator now quotes every path, validates each directory, and comments any missing paths in the script.

⏱️ Switched FreeFactoryNotifyRunner.sh to 4-field output with timestamps and sane excludes:
--timefmt '%F %T' --format '%T|%w|%e|%f' --exclude '\.swp$' --exclude '~$' --exclude '\.tmp$' --exclude '\.part$' --exclude '\.crdownload$' --exclude '\.kate-swp$' --exclude '\.DS_Store$'
(Paths are always shell-quoted.)

🧰 Hardened FreeFactoryNotify.sh:

set -Eeuo pipefail, predictable logging, and 3/4-field stdin parser (back-compatible with older 3-field runners).

Safe path join (%w + %f) and optional “soft settle” window using AppleDelaySeconds from ~/.freefactoryrc (default 2s; exits early once size stabilizes).

Direct hand-off to FreeFactoryConversion.py (no more Tcl fallback):
--daemon --sourcepath <dir> --filename <file> --notify-event <event>
(PYTHONUNBUFFERED=1 for timely logs.)

🧭 Logging & systemd:

Documented user-unit logging (journalctl --user -u freefactory-notify -f) and ensured unit captures stdout/stderr (StandardOutput=journal).

Install / Ops

### 📅 New – 2025-08-21

* 🗑️ Removed legacy/deprecated fields and widgets:

  * `VIDEOTARGET` (FFmbc leftover)
  * `AUDIOTAG` (FFmbc leftover)
  * Entire **DepPage** tab (including `THREADS`, `RemoveSourceGlobal`, etc.).
=======
  * Entire **DepPage** tab (including `THREADS`, `RemoveSourceGlobal`, etc.)
  * ✅ Promoted the following to first-class, factory-level options (in `_combo_key_map`):

  * `ENABLEFACTORY`
  * `DELETECONVERSIONLOGS`
  * `DELETESOURCE`
=======
  * `FFMXPROGRAM`
  
>>>>>>> release/1.1.0
* 📝 Added support in **FreeFactoryConversion.py** for:

  * Skipping factories where `ENABLEFACTORY=False`
  * Removing logs on success when `DELETECONVERSIONLOGS=True`
  * Deleting source file on success when `DELETESOURCE=True`
* 📂 Improved logging:

  * Per-file log files are always written on run
  * Logs are automatically deleted when requested (success only)
  * Failures always keep logs, with clear console status
  * Log file names now include parent directory context to avoid collisions
* 🔒 Added file “settle” logic: new files must be older than 2s before processing
* 🖥️ GUI cleanups:

  * Added `checkMatchMinMaxBitrate` checkbox → locks `-minrate`/`-maxrate` to `-b:v`
  * Ghosts automatically when no `VideoBitrate` is set or in streaming context
  * Now has a drop-down menu including File, Tools and Help drop downs with hotkey support (ie CTRL+N = New Factory, CTRL+S = Save Factory, F1 = Help). 
  
=======
  * Updated tooltips for Input Manual Options, Output Manual Options, and Preview Command for clarity

### 📅 New – 2025-08-17

- 🔧 Major Live Stream Manager overhaul — now uses `core.py` for FFmpeg command generation.
- 🧩 Added UI toggles for:
  - Thread Queue Size
  - Audio/Video Stream Mapping from separate inputs
  - Low Latency Input
- 🧠 Added CPU/GPU concurrency tuning in Global Program Settings (affects service only).
- 🧪 Experimental: sample *SRT Streaming Factory* included.
- 🛠 Introduced `migrate_factories.py` tool to auto-update all factories with missing fields.
- Added a menu which inclues New Factory, Save Factory and Delete Factory as well as Tools and Help.
- Created FactoryTools.py which allows to Import, Export, Backup factories and also includes Tools/FactoryTools, a GUI for managing and migrating factories. Import, Export and Backup will eventually be removed from the main UI and live in FactoryTools.py only.

New data fields:
- `INCLUDETQS`: Enable thread queue size (default: `True`)
- `TQSSIZE`: Thread queue size in bytes (default: `512`)
- `LOWLATENCYINPUT`: Low-latency capture (default: `False`)
- `AUTOAPAV`: Auto stream mapping for multiple inputs (default: `False`)

**Usage:**
```bash
python3 migrate_factories.py --add LOWLATENCYINPUT=False,AUTOAPAV=False,INCLUDETQS=True,TQSSIZE=512
```

> 💡 Add `--backup` to generate `.bak` files before modification.

---

### 📅 New – 2025-08-07
- Added **Manual Input Options** (`MANUALOPTIONSINPUT`) for pre-`-i` FFmpeg flags.

---

### 📅 New – 2025-07-14
- Added support for **Video Profile** and **Profile Level**.
- Fixed missing `-b:v` bug in dropzone, batch encoding, and preview (present in RC1, fixed in RC2).
- Added **Import**, **Export**, and **Backup** buttons for Factory management.

---

### 📅 New – 2025-06-26
- Initial support for **Live Streaming** via Stream Manager tab.
- Added UI controls for `freefactory-notify.service`.

---

## 🗺️ Planned Features / To-Do

- ✅ Dynamic UI: only show valid `pix_fmt`, audio, and video profiles based on selected codec
- ✅ Batch queue with mixed Factories
- 🔄 Rewrite `FreeFactoryConversion.tcl` in Python (as of 2025-08-22 this has been completed but still may need some minor work). FreeFactoryConversion.tcl is now officially broken. Several keys in the factory files have been removed that FFC.tcl once relied on. With the changeover to a python FreeFactoryConversion.py, it is just not worth to keep the .tcl version up to date. Sorry for the inconvience.
=======
- 🔄 Rewrite `FreeFactoryConversion.tcl` in Python
- 🪟 Port FreeFactoryQT to Windows (experimental; may be limited by background service)

---

## 🧠 Notes

> FreeFactoryQT and the FreeFactory Conversion Service are **completely independent**:
> - Use the GUI for hands-on or dropzone-based encoding
> - Use the service for fully automated background workflows

FreeFactoryQT will eventually support integration with external tools like:
- [Demucs](https://github.com/facebookresearch/demucs) for stem separation
- [sox-dsd](https://github.com/peterekepeter/sox-dsd) for DSD audio processing

---
