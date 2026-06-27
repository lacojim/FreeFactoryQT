# Changelog
All notable changes to this project will be documented in this file.

This project loosely follows [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

## [1.1.60-dev] - 2026-06-27
 - Added **Timecode Mode** and **Start Timecode** controls to the **Advanced Video** tab. Timecode Mode provides three options: **Default**, **DF (Drop Frame)**, and **NDF (Non-Drop Frame)**. Selecting DF or NDF automatically formats the Start Timecode field using the appropriate separator (semicolon or colon) and allows the starting timecode to be customized.
 - By default, FFmpeg writes MXF files using **Non-Drop Frame (NDF)** timecode unless the `-timecode` option is specified. This can cause compatibility issues with some professional broadcast playout systems that expect **Drop Frame (DF)** timecode. The new Timecode controls allow this behavior to be overridden without using **Manual Output Options**.
 - Timecode is stored as container metadata and can therefore be modified without re-encoding the video or audio. When used with **Video Copy** (`-c:v copy`) and **Audio Copy** (`-c:a copy`), FreeFactory can update the starting timecode by remuxing the file, producing an almost instantaneous conversion with no loss of quality.


## [1.1.59-dev] - 2026-06-25
 - Removed a really annoying tooltip that kept appearing on black spaces in the UI. 

## [1.1.58-dev] - 2026-06-19
 - Added a New Factory dialog that prompts for Factory Filename, Output Directory, and optional Description when creating a new Factory.
 - Added validation to the New Factory dialog to prevent creation of Factories with missing required information.
 - Added a Default Output Path setting to Global Settings. New Factories now automatically use this path as the default Output Directory.
 - Fixed New Factory clearing behavior. Factory reset operations are now scoped to the Factory Builder and Stream/Record Manager tabs and no longer clear settings on the Global Settings tab.
 - Assigned object names to the main application tabs to support scoped UI operations and improve future maintainability.

## [1.1.57-dev] - 2026-06-10
 - Added a confirmation dialog before deleting a Factory to prevent accidental deletions.
 - FreeFactoryConversion.py now provides enhanced logging including Factory name, path, modification date/time, file size, and SHA256 checksum. These additions make it much easier to determine exactly which Factory version processed a file when troubleshooting or auditing conversions.


## [1.1.55-dev] - 2026-06-04
 - Fixed automatic loudnorm processing when audio was already within tolerance. Previously, some commercials could be analyzed and marked as successful, but the actual render/conversion was skipped. Files within tolerance now render normally without loudnorm correction.
 
 
## [1.1.54-dev] - 2026-06-01
 - Fixed broken -minrate/-maxrate due to bad indention.
 - Changed -dc to -intra_dc_precision as dc is deprecated. 

 
## [1.1.52-dev] - 2026-05-30
 - Discovered that RPM-packaged installs cannot write factories under `/opt/FreeFactory/Factories`. Factory and configuration storage is being reworked to use XDG-style user-writable locations under `~/.config/FreeFactory` and `~/.local/share/FreeFactory`. This should be fully resolved in the next update.
 - The Default Factories Directory browser in Global Settings can now access hidden directories such as `~/.local` and `~/.config`.
 - Made several cosmetic improvements to the Factory Builder tab, including clearer factory action buttons.


## [1.1.51-dev] - 2026-05-23
 - Added automatic PyQt6 version detection.
 - If PyQt6 <= v6.6 is detected, FreeFactoryQT will automatically load the compatibility UI file (FreeFactory-tabs-compat.ui).
 - Using the -u|-ui|--ui flags overrides automatic UI selection.
 

## [1.1.50-dev] - 2026-05-23
 - Added new make_ui_compat.py utility to convert the .ui files for older Qt6/PyQt6 Designer. 
 - Fix Preview crash when Analysis Reports are enabled.
 - Added CRF (Constant Rate Factor) support to the Video tab.
 - Added **Factory Summary** bar at the bottom of the Factory Builder tab.


## [1.1.44-dev unreleased] - 2026-05-14
- **Addressed Campatibility issue between PyQt6 v6.6 and v6.10+**
 - Added command line option to load a different UI file (-u, -ui, --ui all work).
 - Now includes a compat .ui file (FreeFactory-tabs-compat.ui)
 - At this point, only the alpha FreeFactory file, main_ui_cleanup.py is updated. Please test and once confirmed working, I will push these changes to main.py.
 
## [1.1.43-dev unreleased] - 2026-05-10
### Fixed
- **Notify Service / Packaging**
  - Fixed a major RPM/COPR packaging issue where Global Settings attempted to rewrite:
    `/opt/FreeFactory/bin/FreeFactoryNotifyRunner.sh`
    which fails on packaged installs because the file is root-owned.
  - `FreeFactoryNotifyRunner.sh` is now intended to become a static/read-only script.
  - Notify folders are now read dynamically from `~/.freefactoryrc` instead of regenerating the runner script.
  - Hardened `FreeFactoryNotify.sh` parsing and validation for `AppleDelaySeconds`.

### Added
- **Audio Loudness Analysis / Normalization**
  - Added fully working two-pass FFmpeg `loudnorm` support.
  - Added automatic loudness analysis with measured-value second-pass correction.
  - Added tolerance-based smart rendering:
    - files already within tolerance are skipped automatically.
  - Added batch-safe logging output for future CSV/report generation.
  - Added support for report-only analysis mode.
  - Added support for `volumedetect` analysis reports.

### Improved
- **Audio Processing**
  - Improved loudnorm defaults and testing workflows for music and broadcast PCM sources.
  - Verified proper operation through:
    - GUI rendering
    - dropZone processing
    - FreeFactoryNotify.sh
    - FreeFactoryConversion.py daemon processing

## [1.1.42-dev unreleased] - 2026-05-10

### Added
- Initial implementation of audio analysis framework.
- Added early `loudnorm` integration and report generation support.
- Added initial `volumedetect` analysis support.

## [1.1.41-dev unreleased] 2026-05-06

- BUG FIX: Added the support in core.py for missing Aspect Ratio flag. The widget was there, but the code was missing so it didn't do anything. 
- Added code support for the new audio and video analysis features.


## [1.1.40-dev unreleased] 2026-05-01

- Added new widgets to support audio and video analysis.

## [1.1.39-dev unreleased] 2026-03-23

- Added a few new factories to normalize audio in LUFS.

## [1.1.38-dev unreleased] - 2025-12-27

- Rearranged flags to advanced section in dictionary. Added early Piper support.

## [1.1.37-dev] - 2025-10-10

- Add movflags builder support (under Flags Builder tab). All flags (flags, flags2, fflags, movflags have tooltips from the FFmpeg help.


## [1.1.36-dev] - 2025-10-01

- Various small fixes.


## [1.1.35-dev] - 2025-09-24

### Bug Fix
- **Delete Factory**
  - Deleting a factory was not clearing all fields. Fixed.
  

## [1.1.34-dev] - 2025-09-22

### Added
- **FFlags**
  - Added FFlags to the Video Advanced Flags Builders tab.
    - Further expanded flag options.


## [1.1.33-dev] - 2025-09-21

### Bug Fix
- **UI**
  - Bug Fix **ComboBoxes data cleared when clicking New Factory**
    - By making the newer comboboxes editable, then locking them from manual input, it makes clearing them so much easier. Before doing this fix, all comboboxes were being completely cleared which was very bad.

## [1.1.32-dev] - 2025-09-20

### Added
- **UI**
  - New **Added Constant Frame Rate**
    This is a checkbox below the Frame Rate selector. CheckBox is ghosted if no frame rate is selected. This uses the newer FFmpeg flag "-fps_mode:v cfr" so later versions of FFmpeg are required.


## [1.1.31-dev] - 2025-09-18

### Added
- **UI**
  - New **All Video Advanced now working** 
    DC, Qmin & Qmax now working in Video Advanced. Swapped from QSpinBoxes to QLineEdits.

    
## [1.1.30-dev] - 2025-09-17

### Added
- **UI**
  - New **Most of Video Advanced now working** 
    Color / HDR tab now fully functional. Standards / Field tab now fully functional. DC, Qmin & Qmax moved to DepPage until I can map it out in a more sensible manner.
  - Fixed bug where default factory always showed the first item in the list (if not set) but then saving Globals would make that first item the default. Fixed by forcing a blank field in the first register.
  - Added button to select the Factories directory intead of manually typing it in.

## [1.1.27-dev] - 2025-09-16

### Added
- **UI**
  - New **Multi-Output Support** 
    This adds a checkbox to the Factory Builder tab allowing for creating multiple output files. One example of using mode this would be to convert a 5.1 multi-channel audio file into 6 discrete .wav files.
  - Started adding support for Sidecar Subtitles and eia608_to_smpte436m bitstream filter functionality (The latter requires FFmpeg v8.x).

## [1.1.26-dev] - 2025-09-13

### Added
- **UI**
  - New **Flags Builders tab** 
    This add a checkbox based constructor set to build flags for both -flags and -flags2. All available FFmpeg flags|flags2 are included.

### Notes
- These UI refinements are aimed at better usability and flexibility.

## [1.1.25-dev] - 2025-09-12

### Added
- **UI**
  - New **Timing Controls** group box: consolidated **Start Offset (-ss)** and **Encode Length (-t)** into one section for clarity and ease of use.
  - Added **Advanced Video** tab with four subtabs:
    - **GOP / Frame**
    - **Color / HDR**
    - **Standards / Fields**
    - **Flags Builder**
  - Navigation arrows implemented for stacked pages (later replaced with subtabs).
  - Tooltips for all main tabs and advanced subtabs.
  - **Global Settings**
  - Font size control for the FFmpeg Help window (`HelpFontSize` in `.freefactoryrc`).

### Changed
- **UI Layout**
  - Reorganized major sections into `Video`, `Audio`, and `Video Advanced` tabs (previously grouped in a single crowded view).
  - Moved **Video Advanced** tab to the end for more natural navigation flow.
  - Grouped widgets consistently with their labels to simplify layout movement and improve alignment.
- **Core**
  - Added support for `REMOVEA53CC` factory key: if enabled and codec is compatible (mpeg2video, libx264, hevc), injects `-a53cc 0` into the FFmpeg command.
  - Normalized handling of boolean factory values (accepts `true`, `1`, `yes`).

### Fixed
- **Ghosting/Clearing**
  - Updated `_clear_value()` to handle `QCheckBox` correctly: checkboxes are now only unchecked, not stripped of their text.

### Notes
- These UI refinements are aimed at better usability and preparing for upcoming Sidecar subtitle and Recording feature work.


## [1.1.16-dev] - 2025-09-06

### Added
- **Factories**
  - `ClientConversionHQ-VAAPI_264` (VAAPI-powered H.264 preset)
  - `SpeedupVideo` (time-compression utility)
- **App/Packaging**
  - `bin/version.py` (tracks `__version__ = "1.1.16-dev"`)
  - `FreeFactoryQT.desktop` launcher
- **Docs**
  - Updated `docs/FreeFactoryQT-Documentation.odt/.pdf`

### Changed
- **Factory renames**
  - `AudioHD-2-flac_88200` → `AudioHD-2-wav_32-88200`
  - `ClientConversion` → `ClientConversion-720P`
  - `ClientConversionHQ-HVEC-265` → `ClientConversion-HVEC-1530P`
  - `ClientConversionHQ` → `ClientConversionHQ-1080`
  - `LiveAVStream_FileTest_Audio` → `LiveAVStream_AudioFile`
  - `LiveAVStream_Desktop` → `LiveAVStream_VideoFile`
- **Core/UI**
  - Large internal updates across `main_ui_cleanup.py`, `core.py`, `ffstreaming.py`, `FactoryTools.py`, and `FreeFactory-tabs.ui` (refactors & stability; no intentional breaking changes).
- **Permissions**
  - Normalized executable bits (`0755`) on scripts and desktop files in `bin/`.
- **Repo hygiene**
  - Expanded `.gitignore` for local clutter (e.g., `export/`, `*-bak`, `*.bak`).

### Removed
- **Factories** (deprecated/duplicates)
  - `ClientConversionHQ-HVEC-265-1080`, `HDAudio-2-flac_88200`, `HQ-NVENC264`,
    `LiveAVStream_FileTest`, `MythTVConversion`, `Omninon-with-Subs`,
    `PhotoConversion`, `Testing-AllFieldsFilledOut2`, `WDTV-Captions`
- Obsolete backup artifact: `bin/migrate_factories.py-bak`

### Notes
- This is a development snapshot. Tag as `v1.1.16-dev` if you need a reproducible checkpoint.

## [1.1.15] - Unreleased

### Added
- **Recording pipeline (foundations)**
  - **Single-source audio rule**: The recording path now treats audio as a *single source* by design (EmbeddedOnly, PulseOnly, BothMix, None). We always emit explicit `-map` lines so duplicate audio tracks don’t sneak into the command.
  - **Mute mode**: Clean `-an` path when no audio is desired.
  - **x11grab inputs**: Display, geometry/region, and framerate surfaced as first-class input knobs.
  - **v4l2 inputs (webcams/capture cards)**: Device, framerate, `-video_size`, and **input** format (`-input_format` e.g., `mjpeg`, `yuyv422`), plus optional buffering knobs (thread queue size, `-rtbufsize`) for flaky USB cams.
  - **Heuristic defaults** (can be overridden): x11grab defaults to Pulse audio; v4l2 defaults to the camera’s own audio device (if one is specified).
- **Codec “copy” UX (popup-free)**  
  Selecting **VideoCodec=copy** or **AudioCodec=copy** now *clears and ghosts* conflicting widgets **and their labels** (using `l_<WidgetName>` convention). During factory load, values aren’t cleared—only ghosted to reflect state.

### Changed
- **Explicit stream mapping**  
  The recorder/builder always emits `-map` for video/audio, preventing ffmpeg from auto-adding an extra audio track. This is the main antidote to the earlier “two audios in the CMD” issue.
- **Signal wiring simplified (PyQt6-safe)**  
  Removed `textActivated` branch and PyQt5-style overloads. We now wire a single, idempotent handler via `currentTextChanged`, avoiding double-fires and KeyError on `[str]` overloads.
- **Copy-lock configuration**  
  Introduced module-level lists `VIDEO_COPY_WIDGETS` / `AUDIO_COPY_WIDGETS` to declare which widgets are affected by copy mode; labels auto-ghost via the `l_` prefix. Easier maintenance as the UI evolves.

### Fixed
- **Double audio in recordings**  
  Commands could previously include both Pulse and embedded camera audio. With explicit mapping and a single-source rule, only the intended track is recorded (unless an explicit mix is requested in the future).
- **Programmatic load stability**  
  Factory selection now blocks signals while populating fields; all widgets fill correctly, and copy-mode ghosting is applied once at the end—no clearing during loads.
- **PyQt6 signal mismatch**  
  Removed `currentIndexChanged[str]` usage to eliminate `KeyError: 'there is no matching overloaded signal'`.
- **Name scoping for copy-lists**  
  `VIDEO_COPY_WIDGETS`/`AUDIO_COPY_WIDGETS` defined at module scope so helpers can reference them reliably (no more `NameError`).

### Notes
- The “BothMix” mode (mixing Pulse + embedded to a single track via `-filter_complex amix`) is planned but not required for the single-source guarantee and is off by default.

---

## [1.1.1] - 2025-08-28

### Added
- **Factory Tools Updated**: Now includes batch import/export as both flat files or zipped. Local paths and filename keys within factories are removed automatically on export. If you need to retain these keys for in house use, just copy the needed factory file(s) to the new location or use the Backup feature. Import/Export is meant to used for sharing factories publically on the Internet. Not for backing up.
- **UI updates**
- **Menu**: Added Custom menu which contains "Add Factory to Stream Table" or use CTRL+INS. This simplifies having to select a Factory on the Builder tab, then click to the Streaming tab and click "Add Stream" there. Just use CTRL+INS, click the next streaming factory, repeat. Builds the list without changing tabs. (Largely untested and Experimental)

## [1.1.0] - 2025-08-26

### Added
- **Read files in real time**: checkbox `checkReadFilesRealTime` inserts `-re` before file-like inputs (video/audio).  
- **File pickers**: `AddStreamFile` and `AddAudioStreamFile` open a chooser, populate `streamInputVideo/Audio`, and auto-select `file` in the corresponding Force Format combo.
- **Status bar toasts** for streaming actions: started, stopped, finished, removed, and stop-all.
- **TTY restorer** on app exit to avoid needing `reset` in the shell (restores `stty`, cursor, and wrapping).

### Changed
- **Streaming tab now delegates** command assembly to `core.build_streaming_command(...)` (UI no longer crafts input flags).
- **New Factory reset simplified**: clears all `QLineEdit`s, safe-resets Force-Format combos (without nuking items), and forces **Mode → Off** (`StreamMgrMode.setCurrentIndex(0)`).
- **Manual input pre-options** are injected only for *capture* inputs (not for file/concat inputs).
- **Audio Force Format presets** include `file` (explicit audio-from-file path).

### Fixed
- **Row-scoped Stop**: per-row `row_uid` mapping ensures Stop affects the correct worker (no more “row 1 stops row 2”).
- **Start All** reuses the single-row start path, so status progresses **Starting… → Live** reliably.
- **Force-Format combos** no longer lose their items on reset (we stopped calling `.clear()` on `QComboBox`).
- **File inputs**: removed erroneous `-f file` and input queue flags; `-re` is placed right before the file’s `-i`.
- **Playlist groundwork**: treat `concat` as file-like (no TQS; eligible for `-re`), enabling text-file playlists.
- **`UnboundLocalError` in `core.add_input()`** fixed by switching to `cmd.extend(...)` inside the helper.

### Notes
- If an RTMP endpoint rejects audio-only streams, pair audio with a tiny black video (`lavfi color=black`) and add `-shortest` to stop when audio ends.
- “Add Stream” global shortcut was explored but deferred; menu-based action works if needed. Select Factory LiveAVStream_AudioFile for an example of this.
