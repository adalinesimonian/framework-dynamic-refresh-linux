#!/bin/bash

# This script uninstalls the refresh-switch setup by removing:
# - The udev rule file /etc/udev/rules.d/99-refresh-switch.rules
# - The sudoers drop-in file /etc/sudoers.d/refresh-switch (leaving the main sudoers intact)
# - The scripts /usr/local/bin/trigger-refresh.sh and /usr/local/bin/change-refresh.sh
#
# Run this as root (e.g. via sudo).

set -e

# Check that the script is being run as root.
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

echo "Removing udev rule..."
UDEV_RULE="/etc/udev/rules.d/99-refresh-switch.rules"
if [ -f "$UDEV_RULE" ]; then
    rm -f "$UDEV_RULE"
    echo "Removed $UDEV_RULE"
else
    echo "Udev rule not found: $UDEV_RULE"
fi

echo "Removing sudoers drop-in file..."
SUDOERS_FILE="/etc/sudoers.d/refresh-switch"
if [ -f "$SUDOERS_FILE" ]; then
    rm -f "$SUDOERS_FILE"
    echo "Removed $SUDOERS_FILE"
else
    echo "Sudoers drop-in file not found: $SUDOERS_FILE"
fi

echo "Removing refresh scripts from /usr/local/bin..."
for script in trigger-refresh.sh change-refresh.sh; do
    TARGET="/usr/local/bin/$script"
    if [ -f "$TARGET" ]; then
        rm -f "$TARGET"
        echo "Removed $TARGET"
    else
        echo "Script not found: $TARGET"
    fi
done

echo "Reloading udev rules..."
udevadm control --reload

echo "Uninstallation complete."
echo
echo "You may also want to remove the following packages, if they are no"
echo "longer needed:"
echo
echo "  - xmlstarlet"
echo "  - xrandr"
echo "  - gnome-monitor-config"
echo
echo "On Fedora, these can be removed with:"
echo
echo "  sudo dnf remove xmlstarlet xrandr gnome-monitor-config"
