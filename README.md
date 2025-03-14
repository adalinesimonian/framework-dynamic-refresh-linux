# framework-dynamic-refresh-linux

A collection of bash scripts specifically designed for the Framework 13 laptop with a 2.8K screen. These scripts dynamically adjust the monitor refresh rate between 120 Hz when connected to AC power and 60 Hz when on battery, potentially extending battery life by about 1 hour, as tested.

This setup has currently only been tested on Fedora 41. It may work both on other versions and other distros, but it is not guaranteed that it will.

## Prerequisites

- xmlstarlet
- upower
- xrandr
- gnome-monitor-config

On Fedora, these can be installed as follows:

```bash
sudo dnf install xmlstarlet upower xrandr gnome-monitor-config
```

## Installation

Clone the repository:

```bash
git clone https://github.com/adalinesimonian/framework-dynamic-refresh-linux.git
cd framework-dynamic-refresh-linux
```

Run the installation script as root:

```bash
sudo ./install.sh
```

This will:

- Copy the necessary scripts to `/usr/local/bin`.
- Create a udev rule at `/etc/udev/rules.d/99-refresh-switch.rules`.
- Set up a sudoers drop-in file to preserve `XDG_RUNTIME_DIR`.

## Uninstallation

To remove the setup, run the uninstallation script as root:

```bash
sudo ./uninstall.sh
```

## How it works

- **Trigger script:**  
  The `trigger-refresh.sh` script detects active display sessions on the Framework 13 laptop and launches the `change-refresh.sh` script within each user's context.

- **Change script:**  
  The `change-refresh.sh` script checks the power state and toggles the refresh rate:
  - Sets 120 Hz when on AC power.
  - Sets 60 Hz when on battery power.

## Licence

[ISC](LICENCE)
