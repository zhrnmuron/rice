#!/bin/bash

# Paths to battery and AC configurations
BATTERY_CONFIG="$HOME/.config/hypr/hyprland_battery.conf"
AC_CONFIG="$HOME/.config/hypr/hyprland_ac.conf"
CURRENT_CONFIG="$HOME/.config/hypr/hyprland.conf"
BACKUP_CONFIG="$HOME/.config/hypr/hyprland_backup.conf"

# Path to battery status
STATUS_FILE="/sys/class/power_supply/BAT1/status"

# Check if battery status file exists
if [ -f "$STATUS_FILE" ]; then
    BATTERY_STATUS=$(cat "$STATUS_FILE")

    # Backup current config
    cp "$CURRENT_CONFIG" "$BACKUP_CONFIG"

    if [ "$BATTERY_STATUS" == "Discharging" ]; then
        # Switch to battery config
        cp "$BATTERY_CONFIG" "$CURRENT_CONFIG"
        hyprctl reload
        echo "Switched to battery config"
    else
        # Switch to AC config
        cp "$AC_CONFIG" "$CURRENT_CONFIG"
        hyprctl reload
        echo "Switched to AC config"
    fi
else
    echo "Battery status file not found"
fi
