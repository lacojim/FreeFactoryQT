# This is the python3 module for controlling the FreeFactory service functions within the Global Program Settings Tab.

import subprocess
from pathlib import Path
from PyQt6.QtWidgets import QMessageBox, QMenu
from PyQt6.QtCore import Qt

SERVICE_NAME = "freefactory-notify.service"

def _get_remote_host(main_window) -> str:
    host_widget = getattr(main_window, "notifyRemoteHost", None)
    if host_widget is None:
        return ""
    try:
        return (host_widget.text() or "").strip()
    except Exception:
        return ""

def run_notify_service_command(main_window, action: str):
    """Run systemctl command (locally or via SSH) and show output in listNotifyServiceStatus."""
    host = _get_remote_host(main_window)

    if host:
        # Remote: do not try to guess --user; rely on remote system configuration.
        cmd = ["ssh", host, "systemctl", action, SERVICE_NAME]
    else:
        # Local: prefer user service if present
        cmd = ["systemctl"]
        user_service_exists = Path.home().joinpath(".config/systemd/user/" + SERVICE_NAME).exists()
        if user_service_exists:
            cmd.append("--user")
        cmd += [action, SERVICE_NAME]

    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True)
        main_window.listNotifyServiceStatus.addItem(f"✅ {action.upper()} succeeded:")
        for line in output.strip().splitlines():
            main_window.listNotifyServiceStatus.addItem(f"  {line}")
    except subprocess.CalledProcessError as e:
        main_window.listNotifyServiceStatus.addItem(f"❌ {action.upper()} failed:")
        for line in e.output.strip().splitlines():
            main_window.listNotifyServiceStatus.addItem(f"  {line}")

    if action in {"start", "stop", "restart", "kill"}:
        run_notify_service_command(main_window, "status")


def update_notify_service_mode_display(main_window):
    """Update label showing service mode or remote host indicator."""
    host = _get_remote_host(main_window)
    label = main_window.labelNotifyServiceMode

    if host:
        label.setText(f"Service Mode: 🌐 Remote ({host})")
        label.setStyleSheet("color: #8a2be2; font-weight: bold;")
        return

    user_path = Path.home() / ".config/systemd/user" / SERVICE_NAME
    system_path = Path("/etc/systemd/system/") / SERVICE_NAME

    if user_path.exists():
        label.setText("Service Mode: 🧍 User")
        label.setStyleSheet("color: #2e8b57; font-weight: bold;")
    elif system_path.exists():
        label.setText("Service Mode: 🛡️ Root")
        label.setStyleSheet("color: #1e90ff; font-weight: bold;")
    else:
        label.setText("Service Mode: ⚠️ Not Installed")
        label.setStyleSheet("color: #cc0000; font-weight: bold;")


def show_notify_service_menu(main_window, position):
    """Show right-click context menu for labelNotifyServiceMode."""
    menu = QMenu()
    refresh_action = menu.addAction("🔄 Refresh")
    action = menu.exec(main_window.labelNotifyServiceMode.mapToGlobal(position))

    if action == refresh_action:
        update_notify_service_mode_display(main_window)


def connect_notify_service_controls(main_window):
    """Wire up Notify Service buttons and label context menu."""
    main_window.startNotifyServiceButton.clicked.connect(lambda: run_notify_service_command(main_window, "start"))
    main_window.stopNotifyServiceButton.clicked.connect(lambda: run_notify_service_command(main_window, "stop"))
    main_window.restartNotifyServiceButton.clicked.connect(lambda: run_notify_service_command(main_window, "restart"))
    main_window.killNotifyServiceButton.clicked.connect(lambda: run_notify_service_command(main_window, "kill"))
    main_window.statusNotifyServiceButton.clicked.connect(lambda: run_notify_service_command(main_window, "status"))

    main_window.labelNotifyServiceMode.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
    main_window.labelNotifyServiceMode.customContextMenuRequested.connect(
        lambda pos: show_notify_service_menu(main_window, pos)
    )
    main_window.labelNotifyServiceMode.setCursor(Qt.CursorShape.PointingHandCursor)
