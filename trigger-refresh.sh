#!/bin/bash

# This script finds all active sessions and launches the refresh-change script
# in each user's context.

# Redirect stdout and stderr to syslog, tagged with "trigger-refresh".
exec 1> >(logger -t trigger-refresh -s) 2>&1

# Loop over active sessions using loginctl.
for session in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
    SESSION_TYPE=$(loginctl show-session "$session" -p Type | cut -d= -f2)
    if [ "$SESSION_TYPE" != "x11" ] && [ "$SESSION_TYPE" != "wayland" ]; then
        echo "Skipping session $session (type: $SESSION_TYPE)"
        continue
    fi

    active=$(loginctl show-session "$session" -p Active | cut -d= -f2)
    if [ "$active" = "yes" ]; then
        user=$(loginctl show-session "$session" -p Name | cut -d= -f2)
        uid=$(id -u "$user")
        runtime_dir="/run/user/$uid"

        echo "Triggering refresh-change for session $session (user: $user, uid: $uid)"

        # Launch the refresh-change script in the user's session using systemd-run.
        sudo -u "$user" XDG_RUNTIME_DIR="$runtime_dir" \
            systemd-run --user /usr/local/bin/change-refresh.sh
    fi
done
