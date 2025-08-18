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

<img width="1101" height="730" alt="image" src="https://github.com/user-attachments/assets/c0269e1a-9ce6-457a-b218-53a36bf33e72" />


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

---

## ✍ Example: Advanced Manual FFmpeg Options

Even highly specialized commands can be stored in a Factory. For example:

```bash
-c:v mpeg2video -pix_fmt yuv422p -aspect 16:9 -intra_vlc 1 -b:v 50000000 -minrate 50000000 -maxrate 50000000 -bufsize 17825792 -rc_init_occupancy 17825792 -bf 2 -non_linear_quant 1 -color_primaries bt709 -color_trc bt709 -colorspace bt709 -seq_disp_ext 1 -video_format component -color_range 1 -chroma_sample_location topleft -signal_standard 4 -dc 8 -qmin 5 -qmax 23 -g 12 -field_order tt -top 1 -flags +ildct+ilme -alternate_scan 1 -c:a pcm_s24le -ar:a 48000
```

These would be stored under the `Manual Options` field in your Factory, and saved for future use.

---

## 🆕 Changelog

### 📅 New – 2025-08-17

- 🔧 Major Live Stream Manager overhaul — now uses `core.py` for FFmpeg command generation.
- 🧩 Added UI toggles for:
  - Thread Queue Size
  - Audio/Video Stream Mapping from separate inputs
  - Low Latency Input
- 🧠 Added CPU/GPU concurrency tuning in Global Program Settings (affects service only).
- 🧪 Experimental: sample *SRT Streaming Factory* included.
- 🛠 Introduced a beta version of FreeFactoryConversion.py. Can be ran stand-alone for testing. Please do test.
- 🛠 Introduced `migrate_factories.py` tool to auto-update all factories with missing fields.

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
- 🔄 Rewrite `FreeFactoryConversion.tcl` in Python
- 🪟 Port FreeFactoryQT to Windows (experimental; may be limited by background service)

---

## 🧠 Notes

> FreeFactoryQT and the FreeFactory Conversion Service are **completely independent**:
> - Use the GUI for hands-on or dropzone-based encoding
> - Use the service for fully automated background workflows

FreeFactoryQT may eventually support integration with external tools like:
- [Demucs](https://github.com/facebookresearch/demucs) for stem separation
- [sox-dsd](https://github.com/peterekepeter/sox-dsd) for DSD audio processing

---
