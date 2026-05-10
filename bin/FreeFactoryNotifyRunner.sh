#!/bin/bash
# FreeFactoryNotifyRunner.sh
# Watches drop folders recursively and feeds events to FreeFactoryNotify.sh
# This is raun from the freefactory-notify.service

# FORMAT: 4 fields time|dir|event|file
# Static runner: reads NotifyFolders from ~/.freefactoryrc

set -Eeuo pipefail

RC="$HOME/.freefactoryrc"
NOTIFY_SCRIPT="/opt/FreeFactory/bin/FreeFactoryNotify.sh"

if [[ ! -f "$NOTIFY_SCRIPT" ]]; then
  echo "FreeFactoryNotifyRunner: missing $NOTIFY_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$RC" ]]; then
  echo "FreeFactoryNotifyRunner: missing config $RC" >&2
  exit 1
fi

notify_raw="$(
  awk -F= '
    $1 == "NotifyFolders" {
      print $2
      exit
    }
  ' "$RC"
)"

if [[ -z "$notify_raw" ]]; then
  echo "FreeFactoryNotifyRunner: no NotifyFolders configured." >&2
  exit 1
fi

IFS=';' read -r -a folders <<< "$notify_raw"

valid_folders=()
for folder in "${folders[@]}"; do
  folder="${folder/#\~/$HOME}"
  folder="${folder%/}"

  if [[ -d "$folder" ]]; then
    valid_folders+=("$folder")
  else
    echo "FreeFactoryNotifyRunner: skipping missing folder: $folder" >&2
  fi
done

if [[ "${#valid_folders[@]}" -eq 0 ]]; then
  echo "FreeFactoryNotifyRunner: no valid notify folders configured." >&2
  exit 1
fi

/usr/bin/inotifywait -m -r \
  -e close_write,moved_to \
  --timefmt '%F %T' \
  --format '%T|%w|%e|%f' \
  --exclude '\.swp$' \
  --exclude '~$' \
  --exclude '\.tmp$' \
  --exclude '\.part$' \
  --exclude '\.crdownload$' \
  --exclude '\.kate-swp$' \
  --exclude '\.DS_Store$' \
  "${valid_folders[@]}" \
| "$NOTIFY_SCRIPT"
