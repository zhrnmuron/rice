#!/usr/bin/env bash
if pgrep hypridle > /dev/null; then
    pkill hypridle
    notify-send "Hypridle Disabled"
else
    hypridle &
    notify-send "Hypridle Enabled"
fi

