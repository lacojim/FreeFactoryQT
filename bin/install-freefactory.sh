#!/usr/bin/env bash
set -Eeuo pipefail

ARCHIVE="${1:-FreeFactory.tgz}"   # path to the tarball
PREFIX="/opt/FreeFactory"

[[ -f "$ARCHIVE" ]] || { echo "Archive not found: $ARCHIVE" >&2; exit 1; }
echo "→ Installing to $PREFIX from $ARCHIVE"

sudo mkdir -p "$PREFIX"
sudo tar -C / -xzf "$ARCHIVE"

# make sure main scripts are executable
sudo chmod +x "$PREFIX"/bin/FreeFactoryNotify*.sh || true
sudo chmod +x "$PREFIX"/setup-notifyservice.sh || true

echo "→ Running service setup…"
"$PREFIX"/setup-notifyservice.sh   # uses your prompts

echo "✓ Done. Logs: journalctl --user -u freefactory-notify -f"
