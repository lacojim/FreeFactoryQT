# Changelog
All notable changes to this project will be documented in this file.

This project loosely follows [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.9.0] - 2025-08-25

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
- “Add Stream” global shortcut was explored but deferred; menu-based action works if needed.

---
