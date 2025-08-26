#!/usr/bin/env bash
<<<<<<< HEAD
#   FreeFactoryNotify.sh (patched to use Python runner)
# - Keeps the same entry point so systemd unit & UI continue to work.
# - Reads DefaultFactory and MaxConcurrentJobs from ~/.freefactoryrc unless overridden via env.
# - Runs the Python rewrite in watch mode.

set -euo pipefail

APP_DIR="/opt/FreeFactory"
PYTHON_BIN="$(which python3)"
PY_SCRIPT="$APP_DIR/bin/FreeFactoryConversion.py"

MAXJOBS="${FREEFACTORY_MAX_JOBS:-}"
FLAGS=()
if [[ -n "$MAXJOBS" ]]; then
  FLAGS+=(--max-workers "$MAXJOBS")
fi

# Read "DIR|EVENTS|FILE" safely (filenames with spaces OK)
while IFS='|' read -r DIR EVENTS FILE; do
  echo "[FreeFactoryNotify] EVENT=$EVENTS PATH=${DIR}${FILE}" >&2
  "$PYTHON_BIN" "$PY_SCRIPT" --daemon --sourcepath "$DIR" --filename "$FILE" "${FLAGS[@]}"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "[FreeFactoryNotify] Python exited with code $rc (${DIR}${FILE})" >&2
  fi
done



=======
# FreeFactoryNotify.sh — read inotify events and dispatch a single-file job.

set -Eeuo pipefail

# ----- paths -----
PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"
CONVERTER_PY="${CONVERTER_PY:-/opt/FreeFactory/bin/FreeFactoryConversion.py}"

if [[ ! -f "$CONVERTER_PY" ]]; then
  echo "[FreeFactoryNotify] ERROR: converter not found at $CONVERTER_PY"
  exit 1
fi

# Unbuffer Python so logs show promptly in journald (user unit)
export PYTHONUNBUFFERED=1

# ----- settle time (default 2s; override via ~/.freefactoryrc AppleDelaySeconds=NN) -----
SETTLE_SECS=2
RC="$HOME/.freefactoryrc"
if [[ -f "$RC" ]]; then
  rc_settle="$(grep -E '^AppleDelaySeconds=' "$RC" | sed -E 's/^[^=]+=([0-9]+)/\1/' || true)"
  if [[ -n "$rc_settle" ]]; then SETTLE_SECS="$rc_settle"; fi
fi

settle_file() {
  # wait until file size stops changing or timeout reached
  local p="$1"
  local timeout="${2:-0}"
  local end=$((SECONDS+timeout)) last=-1 curr=-2
  while (( SECONDS < end )); do
    [[ -f "$p" ]] || return 1
    curr=$(stat -c%s -- "$p" 2>/dev/null || echo -1)
    if [[ "$curr" -eq "$last" && "$curr" -gt 0 ]]; then return 0; fi
    last="$curr"
    sleep 1
  done
  return 0
}

# NOTE: plain echo -> captured by your *user* unit:
#   journalctl --user -u freefactory-notify -f

# Accept either:
#  - 4 fields (timestamp | dir | event | file)  -> '%T|%w|%e|%f'
#  - 3 fields (dir | event | file)              -> '%w|%e|%f'
while IFS='|' read -r f1 f2 f3 f4; do
  if [[ -n "${f4:-}" ]]; then
    ts="$f1"; watch_dir="$f2"; event="$f3"; filename="$f4"
  else
    ts="";    watch_dir="$f1"; event="$f2"; filename="$f3"
  fi

  # Build full path
  case "$watch_dir" in
    */) full_path="${watch_dir}${filename}" ;;
    *)  full_path="${watch_dir}/${filename}" ;;
  esac

  echo "[FreeFactoryNotify] DROP DETECTED: ${full_path} (event=${event}) ts=${ts:-N/A}"

  # Runner already filters to close_write,moved_to; harmless to double-check
  if [[ "$event" != *"MOVED_TO"* && "$event" != *"CLOSE_WRITE"* ]]; then
    continue
  fi

  # Ensure file exists and is stable
  [[ -f "$full_path" ]] || continue
  if ! settle_file "$full_path" "$SETTLE_SECS"; then
    echo "[FreeFactoryNotify] WARNING: file disappeared during settle: $full_path"
    continue
  fi

  # Hand off to Python worker; FFC discovers the correct factory by NOTIFYDIRECTORY (no --factory).
  src_dir="${watch_dir%/}"
  base_name="$filename"

  echo "[FreeFactoryNotify] RUN: $PYTHON_BIN \"$CONVERTER_PY\" --daemon --sourcepath \"$src_dir\" --filename \"$base_name\" --notify-event \"$event\" &"
  "$PYTHON_BIN" "$CONVERTER_PY" \
    --daemon \
    --sourcepath "$src_dir" \
    --filename "$base_name" \
    --notify-event "$event" \
    &
done
>>>>>>> release/1.1.0
