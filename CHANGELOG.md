# Changelog
All notable changes to this project will be documented in this file.

This project loosely follows [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).


## [1.1.33-dev] - 2025-09-21

### Added
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
