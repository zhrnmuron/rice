#!/bin/bash

FOCUS_FLAG="/tmp/focus_mode_active"

if [ -f "$FOCUS_FLAG" ]; then
    # Focus mode is active, turn it off: restart apps
    pkill -f discord
    pkill -f signal-desktop
    sleep 1  # Ensure processes are fully stopped
    # Use setsid or remove nohup if issues persist
    setsid discord > /dev/null 2>&1 &
    setsid signal-desktop > /dev/null 2>&1 &    rm "$FOCUS_FLAG"
    notify-send "Focus Mode Disabled"
else
    # Focus mode is inactive, turn it on: kill apps
    pkill -f discord
    pkill -f signal-desktop
    touch "$FOCUS_FLAG"
    notify-send "Focus Mode Enabled"
    # Optional: persistent kill loop
    while [ -f "$FOCUS_FLAG" ]; do
        pkill -f discord
        pkill -f signal-desktop
        sleep 15
    done &
fi

