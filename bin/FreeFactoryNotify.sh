#!/usr/bin/env bash
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



