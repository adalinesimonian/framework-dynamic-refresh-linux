#!/bin/bash

# This script installs the refresh-switch setup:
# - Copies trigger-refresh.sh and change-refresh.sh from the current directory to /usr/local/bin
# - Creates a udev rule at /etc/udev/rules.d/99-refresh-switch.rules
# - Creates a sudoers drop-in file at /etc/sudoers.d/refresh-switch to keep XDG_RUNTIME_DIR
#
# Run this as root (e.g. via sudo).

set -e

# Check that the script is being run as root.
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# Check that the required scripts exist in the current directory.
for script in trigger-refresh.sh change-refresh.sh; do
    if [ ! -f "$script" ]; then
        echo "Error: Required script '$script' not found in the current directory."
        exit 1
    fi
done

echo "Copying trigger-refresh.sh and change-refresh.sh to /usr/local/bin..."
cp trigger-refresh.sh /usr/local/bin/
cp change-refresh.sh /usr/local/bin/

# Set correct permissions (executable, owner root)
chmod 755 /usr/local/bin/trigger-refresh.sh /usr/local/bin/change-refresh.sh

echo "Creating udev rule..."
UDEV_RULE="/etc/udev/rules.d/99-refresh-switch.rules"
cat >"$UDEV_RULE" <<'EOF'
SUBSYSTEM=="power_supply", ATTR{online}=="0|1", RUN+="/usr/local/bin/trigger-refresh.sh"
EOF
chmod 644 "$UDEV_RULE"

echo "Creating sudoers drop-in file for refresh-switch..."
SUDOERS_FILE="/etc/sudoers.d/refresh-switch"
cat >"$SUDOERS_FILE" <<'EOF'
Defaults env_keep += "XDG_RUNTIME_DIR"
EOF
chmod 0440 "$SUDOERS_FILE"

echo "Reloading udev rules..."
udevadm control --reload

echo "Installation complete."
echo
echo "You will need the following commands installed for the scripts to work:"
echo
echo "  - xmlstarlet"
echo "  - upower"
echo "  - xrandr"
echo "  - gnome-monitor-config"
echo
echo "On Fedora, these can be installed with:"
echo
echo "  sudo dnf install xmlstarlet upower xrandr gnome-monitor-config"
