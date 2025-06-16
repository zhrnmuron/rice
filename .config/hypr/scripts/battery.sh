#!/bin/bash

CONFIG_DIR="$HOME/.config/hypr"
PROFILE_LINK="$CONFIG_DIR/hyprland_profile.conf"
AC_CONF="$CONFIG_DIR/ac.conf"
BATTERY_CONF="$CONFIG_DIR/battery.conf"

if [ "$(readlink "$PROFILE_LINK")" = "$(basename "$AC_CONF")" ]; then
    ln -sf "$(basename "$BATTERY_CONF")" "$PROFILE_LINK"
    PROFILE="Battery"
else
    ln -sf "$(basename "$AC_CONF")" "$PROFILE_LINK"
    PROFILE="AC"
fi

hyprctl reload

notify-send "Hyprland Profile Switched" "Active profile: $PROFILE"

