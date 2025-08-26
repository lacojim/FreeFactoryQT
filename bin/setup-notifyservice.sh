#!/usr/bin/env bash

set -Eeuo pipefail
trap 'echo "[setup-notifyservice] error on line $LINENO (exit $?): $BASH_COMMAND" >&2' ERR

SERVICE_NAME="freefactory-notify.service"
USER_PATH="$HOME/.config/systemd/user/$SERVICE_NAME"
SYSTEM_PATH="/etc/systemd/system/$SERVICE_NAME"

echo "🔧 FreeFactory Notify Service Setup"
echo "----------------------------------"

# Check if service is currently running
echo "🔍 Checking if the service is currently running..."

user_active=$(systemctl --user is-active "$SERVICE_NAME" 2>/dev/null || true)
system_active=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || true)

if [[ "$user_active" == "active" ]]; then
    echo "⚠️  The service is currently running in USER mode."
    read -p "Would you like to stop it before proceeding? [y/N]: " stopuser
    if [[ "$stopuser" =~ ^[Yy]$ ]]; then
        systemctl --user stop "$SERVICE_NAME"
        echo "🛑 Stopped user service."
    else
        echo "❌ Please stop the service before continuing."
        exit 1
    fi
elif [[ "$system_active" == "active" ]]; then
    echo "⚠️  The service is currently running in SYSTEM mode."
    read -p "Would you like to stop it before proceeding? [y/N]: " stopsystem
    if [[ "$stopsystem" =~ ^[Yy]$ ]]; then
        sudo systemctl stop "$SERVICE_NAME"
        echo "🛑 Stopped system-wide service."
    else
        echo "❌ Please stop the service before continuing."
        exit 1
    fi
else
    echo "✅ Service is not currently running."
fi

echo ""
# Detect current mode
user_installed=false
system_installed=false

[[ -f "$USER_PATH" ]] && user_installed=true
[[ -f "$SYSTEM_PATH" ]] && system_installed=true

if $user_installed; then
    echo "📂 Installed in USER mode"
fi

if $system_installed; then
    echo "📂 Installed in SYSTEM-WIDE mode"
fi

if ! $user_installed && ! $system_installed; then
    echo "📂 Service not installed yet."
fi

echo ""
echo "Choose an action:"
echo "1) Install/enable in USER mode"
echo "2) Install/enable in SYSTEM-WIDE mode (requires sudo)"
echo "3) Uninstall from USER mode"
echo "4) Uninstall from SYSTEM-WIDE mode"
echo "5) Quit"

read -p "Selection: " choice

case "$choice" in
    1)
        mkdir -p ~/.config/systemd/user
        cp "$SERVICE_NAME" "$USER_PATH"
        systemctl --user daemon-reload
        systemctl --user enable "$SERVICE_NAME"
        echo "✅ Installed and enabled in user mode"
        read -p "Start the service now? [y/N]: " startnow
        [[ "$startnow" =~ ^[Yy]$ ]] && systemctl --user start "$SERVICE_NAME"
        ;;
    2)
        sudo cp "$SERVICE_NAME" "$SYSTEM_PATH"
        sudo systemctl daemon-reload
        sudo systemctl enable "$SERVICE_NAME"
        echo "✅ Installed and enabled system-wide"
        read -p "Start the service now? [y/N]: " startnow
        [[ "$startnow" =~ ^[Yy]$ ]] && sudo systemctl start "$SERVICE_NAME"
        ;;
    3)
        systemctl --user disable "$SERVICE_NAME"
        rm -f "$USER_PATH"
        systemctl --user daemon-reload
        echo "🗑️  Uninstalled from user mode"
        ;;
    4)
        sudo systemctl disable "$SERVICE_NAME"
        sudo rm -f "$SYSTEM_PATH"
        sudo systemctl daemon-reload
        echo "🗑️  Uninstalled from system-wide mode"
        ;;
    5)
        echo "❎ Exiting..."
        ;;
    *)
        echo "❌ Invalid choice"
        ;;
esac
