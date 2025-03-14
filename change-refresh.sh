#!/bin/bash

# This script changes the resolution, scale, and refresh rate of the primary monitor
# based on the power state (AC or battery). It reads the current resolution, scale,
# and monitor name from monitors.xml (if available) and queries the available modes
# for the primary monitor using gnome-monitor-config. It then selects the mode with
# the refresh rate closest to the desired rate (120 Hz on AC, 60 Hz on battery) and
# sets the monitor to that mode.

# Redirect stdout and stderr to syslog, tagged with "change-refresh".
exec 1> >(logger -t change-refresh -s) 2>&1

# Debounce, schedule the actual call after THRESHOLD seconds if not already scheduled.
debounce_pid_file="$HOME/.cache/change-refresh.pid"
threshold=1 # Number of seconds to debounce by.
mkdir -p "$(dirname "$debounce_pid_file")"
if [ -f "$debounce_pid_file" ] && kill -0 "$(cat "$debounce_pid_file")" 2>/dev/null; then
    echo "Debounce: job already scheduled; exiting."
    exit 0
fi

# Write current PID.
echo $$ >"$debounce_pid_file"

# Sleep in the foreground.
sleep "$threshold"

# Get current resolution, scale, and monitor name from monitors.xml.

config_file="$HOME/.config/monitors.xml"
if [ -f "$config_file" ]; then
    # Read the primary logical monitor info.
    width=$(xmlstarlet sel -t -v '//logicalmonitor[primary="yes"]/monitor/mode/width' "$config_file")
    height=$(xmlstarlet sel -t -v '//logicalmonitor[primary="yes"]/monitor/mode/height' "$config_file")
    scale=$(xmlstarlet sel -t -v '//logicalmonitor[primary="yes"]/scale' "$config_file")
    monitor_name=$(xmlstarlet sel -t -v '//logicalmonitor[primary="yes"]/monitor/monitorspec/connector' "$config_file")
fi

# Fallback if resolution not found (using xrandr).
if [ -z "$width" ] || [ -z "$height" ]; then
    # shellcheck disable=SC2063
    mode=$(xrandr | grep '*' | head -n1 | awk '{print $1}')
    width=${mode%x*}
    height=${mode#*x}
    monitor_name=$(xrandr | grep " connected" | awk '{print $1}' | head -n1)
fi

# Fallback for scale: if not set in monitors.xml, try parsing it from
# gnome-monitor-config list.
if [ -z "$scale" ]; then
    scale=$(gnome-monitor-config list | awk '
            /Monitor \[ '"${monitor_name}"'\]/ { flag=1 }
            flag && /CURRENT/ {
                match($0, /preferred scale = ([^ ]+)/, arr);
                print arr[1];
                flag=0
            }
        ')
    [ -z "$scale" ] && scale="1"
fi

# Determine desired refresh rate based on power state.
ac_state=$(upower -i "$(upower -e | grep 'line_power')" | grep "online" | awk '{print $2}')
if [ "$ac_state" = "yes" ]; then
    desired_refresh=120
else
    desired_refresh=60
fi

# Query available modes for the primary monitor, using gnome-monitor-config, that
# match the current resolution.
available_lines=$(gnome-monitor-config list | awk -v mon="$monitor_name" -v res="${width}x${height}" '
      $0 ~ "Monitor \\[ "mon" \\]" {flag=1}
      flag && $1 ~ res"@" {print $0}
      flag && /^$/ {flag=0}
    ')

# Choose the mode whose refresh rate is closest to desired_refresh.
best_mode_id=""
best_diff=10000
while IFS= read -r line; do
    # Example line format:
    # 2880x1920@60.0006 [id: '2880x1920@60.001'] [preferred scale = 2 ...]

    # Extract the refresh rate from the first field:
    raw_mode=$(echo "$line" | awk '{print $1}') # e.g. "2880x1920@60.0006"
    rate=$(echo "$raw_mode" | cut -d'@' -f2)

    # Compute absolute difference.
    diff=$(awk -v r1="$rate" -v r2="$desired_refresh" 'BEGIN { diff = (r1>r2 ? r1 - r2 : r2 - r1); printf "%.4f", diff }')

    # If this diff is smaller, save this mode's ID.
    cmp=$(awk -v d1="$diff" -v d2="$best_diff" 'BEGIN { print (d1 < d2 ? 1 : 0) }')
    if [ "$cmp" -eq 1 ]; then
        best_diff="$diff"

        # Extract the ID from the line ([id: '...']).
        best_mode_id=$(echo "$line" | grep -oP "\[id: '\K[^']+")
    fi
done <<<"$available_lines"

# If no matching mode is found, fall back to constructing an ID from our desired
# refresh.
if [ -z "$best_mode_id" ]; then
    best_mode_id="${width}x${height}@${desired_refresh}"
fi

echo "Setting monitor $monitor_name to resolution ${width}x${height}, \
scale ${scale}, refresh rate mode ID ${best_mode_id} (desired ${desired_refresh} Hz)"
gnome-monitor-config set -LpM "${monitor_name}" -s "${scale}" -m "${best_mode_id}"

rm -f "$debounce_pid_file"

exit 0
