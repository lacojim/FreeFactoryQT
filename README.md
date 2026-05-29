![image](https://github.com/user-attachments/assets/9cca7be8-736b-4768-8cd6-79cbd008605a)
# FreeFactoryQT
<img width="1112" height="779" alt="image" src="https://github.com/user-attachments/assets/44f3aea2-075b-487f-93c4-83b355c4f117" />


> ⚠️ **Note:** Changelogs: https://github.com/lacojim/FreeFactoryQT/blob/main/CHANGELOG.md

---

## 🎬 What is FreeFactoryQT?

**FreeFactory** is a powerful, user-friendly media conversion system designed for both casual users and broadcast professionals. Originally developed for in-house use at a television station by a broadcast engineer with 40 years of experience, it has evolved from a set of BASH scripts into a full-featured Python3 application with a Qt6 interface.

While **FreeFactory** is designed to make using FFmpeg easier, it supports nearly EVERY FFmpeg option available making FreeFactory the most capable front end for FFmpeg in existence today. While we attempt to hide options that are not compatible with each other from being selected, it is and will be an ongoing process as FFmpeg is a most complicated project. Most common options are currently supported. We thrive to be the closest GUI to an (un)offical GUI as possible, which does not exist.

**FreeFactory** simplifies complex encoding workflows into reusable, shareable *Factories*. While FFmpeg is incredibly powerful, its syntax can be intimidating — **FreeFactory** makes it all accessible without sacrificing any advanced capability.

The real hidden power within **FreeFactory** is the notify service. This allows creating shared (local or network) dropboxes which have a dedicated Factory assigned to each of them. Once a file is copied into one of these drop folders, the background service will pick it up, process it according to factory specifications of the folder and deliver to the outbox. Completely transparent to the user. This is a fantastic feature for production houses, television stations and news operations alike. It is highly recommended to have a dedicated FreeFactory server for high usage facilities. 

FreeFactory is currently included with the **AVLinux** distribution: https://www.bandshed.net/2026/03/01/av-linux-and-mx-moksha-25-1-released/ . Also available for Fedora Linux through the FreeFactoryQT COPR repository: https://copr.fedorainfracloud.org/coprs/lexridge/freefactoryqt/ . Supprted releases for Fedora 42, 43 and 44. We would most welcome packagers for other distributions to help make this more available to package managers.

---

## 🚀 Key Features

- Design and save reusable conversion workflows as **Factories**
- GUI-based direct conversion of single or batch files
- Supports drag-and-drop and watched folders
- Clean separation between UI (FreeFactoryQT) and background service (`FreeFactoryConversion.py`)
- Fully compatible with FFmpeg (tested on FFmpeg v7+)
- Easy to use **Flags Builder** for -flags, -flags2, -fflags and -movflags.
- Supports audio/video analysis via two passes. Operates in two modes: Analysis reports only or full analysis and render for audio. Video only supports reports at the moment.

FreeFactory makes sharing encoding setups easy: import a Factory, update the Output and Notify directories, and you're ready to go.
> 📦 Factories are portable and easy to exchange. Only minor path edits are usually required.

---

## What's New
- 2026-05-23 Added CRF (Constant Rate Factor) support to the Video tab. Fixed Preview crash when Analysis Reports are enabled. Added **Factory Summary** bar at the bottom of the Factory Builder tab.
- 2026-05-10 Added Audio and Video analysis. Audio portition is working now. What this can do for example is when correcting audio levels for Broadcast (-24LUFS) or YouTube (-16LUFS), it will scan the file first and build a table of the levels, then on the final pass it will use those anaylized numbers for the full correction, while keeping dynamic range. For now, loudnorm and volumedetect (volumedetect is report only) are supported.This has been a long overdue feature and needed badly for correcting audio on files in our playback server at work. Fix it at the source instead of relying on automatic audio levelers which induce pumping or breathing effects when working.
<img width="818" height="224" alt="image" src="https://github.com/user-attachments/assets/5834e189-ea46-407a-ab9c-2bdb79d0e0e8" />

As you can see in the photo, you first set the filter to something close to what you need, this is the reference point. Once FreeFactory via FFMpeg runs the analysis on the file, it will replace the filter (behind the scenes) with the new filter command then renders the file with the new parameters. So the filter becomes similar to this:

   ```bash
   -af loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=...:measured_TP=...:measured_LRA=...:measured_thresh=...:offset=...:linear=true
   ```
This feature also allows for creating a report text file so you may see the full analysis report for your input file(s). This file gets saved into the Output Directory.  **NOTE:** If Report is checked, it ONLY creates the analysis report and does not render any files. The checkbox is read in real time and is NOT saved in the Factory file.

---

## 🖥️ Installation

**Requirements:**
- Python 3
- PyQt6
- `inotifywait` (only for background service)
- `FFmpeg`, of course.

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

<img width="1100" height="748" alt="image" src="https://github.com/user-attachments/assets/b28ab8c8-06b0-4b5e-994d-d1f284b6cb8b" />

Fully editable factories with support for complex options:

<img width="1099" height="749" alt="livestreamandrecordmgr" src="https://github.com/user-attachments/assets/c85bbc20-8b0d-4ef6-8dc2-9b517c6725b2" />



---

## ⚙️ Setting Up the FreeFactory Service (Optional)

> ⚠️ The FreeFactoryConversion service requires **inotifywait** to be installed.

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

## 🚀 FactoryTools utility. 
This allows for Import/Export/Backup Factories as well as Factory Management such as adding or removing Factory keys. Can also check Factory integrity and for multiple Factories sharing the same Notify Folders. It can be launched stand-alone or from within FreeFactoryQT via the menu or hotkey combination (CTRL+T).

<img width="681" height="382" alt="factorytools" src="https://github.com/user-attachments/assets/e19424b4-0375-48ab-85c0-fcac8b224773" />


---

## 🚀 Advanced Help Tab which utilizes the built-in help of your installed FFmpeg version

<img width="1261" height="752" alt="ffmpeghelp" src="https://github.com/user-attachments/assets/dc514017-a24a-4854-b779-09a91c728c27" />

---

## ✍ Advanced Manual Input and Output FFmpeg Options

Even highly specialized commands can be stored in a Factory.

These are stored under the `Manual Options (both input and output)` fields in your Factory, and saved for future use.
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

## 🗺️ Planned Features / To-Do

- ✅ Dynamic UI: only show valid `pix_fmt`, audio, and video profiles based on selected codec
- ✅ Batch queue with mixed Factories
- ✅ Rewrite `FreeFactoryConversion.tcl` in Python (as of 2025-08-22 this has been completed). FreeFactoryConversion.tcl is now officially broken. It still remains in the archive for reference purposes only but is no longer used.
- ✅ Factory Types. These could include internal, audioonly, video+audio, streaming+record, etc.
- 🪟 Add to Factory Tools an option to create a Factory from a FFMpeg Linux command line.
- 🪟 Create voice-overs using Piper from a text file. This would use a calibration script (text, not code) for each voice model in order to get a proper length estimate.
- 🪟 Add Internal Factories. This would be for creating video countdowns, tone and bars, etc either for streaming or creating a file.
- 🪟 Port FreeFactoryQT to Windows. (Is this really necessary now with WSL?)
  
---

## 🧠 Notes

> FreeFactoryQT and the FreeFactory Conversion Service are **completely independent** with the exception of core.py which is shared:
> - Use the GUI for hands-on or dropzone-based encoding
> - Use the service for fully automated background workflows

---
