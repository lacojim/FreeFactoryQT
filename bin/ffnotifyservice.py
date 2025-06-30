import subprocess
from pathlib import Path
from PyQt6.QtWidgets import QMessageBox, QMenu
from PyQt6.QtCore import Qt

def run_notify_service_command(main_window, action: str):
    """Run systemctl command for notify service and show output in listNotifyServiceStatus."""
    cmd = ["systemctl"]

    user_service_exists = Path.home().joinpath(".config/systemd/user/freefactory-notify.service").exists()
    if user_service_exists:
        cmd.append("--user")

    cmd += [action, "freefactory-notify.service"]

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
    """Update label showing whether service is installed in user or system mode."""
    user_path = Path.home() / ".config/systemd/user/freefactory-notify.service"
    system_path = Path("/etc/systemd/system/freefactory-notify.service")

    if user_path.exists():
        main_window.labelNotifyServiceMode.setText("Service Mode: 🧍 User")
        main_window.labelNotifyServiceMode.setStyleSheet("color: #2e8b57; font-weight: bold;")
    elif system_path.exists():
        main_window.labelNotifyServiceMode.setText("Service Mode: 🛡️ Root")
        main_window.labelNotifyServiceMode.setStyleSheet("color: #1e90ff; font-weight: bold;")
    else:
        main_window.labelNotifyServiceMode.setText("Service Mode: ⚠️ Not Installed")
        main_window.labelNotifyServiceMode.setStyleSheet("color: #cc0000; font-weight: bold;")


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
