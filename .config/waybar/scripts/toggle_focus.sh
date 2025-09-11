#!/bin/bash

FOCUS_FLAG="/tmp/focus_mode_active"

# Edit: list of focus tabs
FOCUS_TABS=(
  "about:newtab"
  "https://perplexity.ai"
  "https://mail.google.com/mail/u/1/#inbox"
  "https://seek.onlinedegree.iitm.ac.in/courses/ns_25t2_ma1003?id=2&type=lesson&tab=courses&unitId=1"
)

# Launch Firefox with focus tabs (one window with multiple tabs)
launch_focus_browser() {
  # shellcheck disable=SC2068
  setsid firefox ${FOCUS_TABS[@]} >/dev/null 2>&1 &
  # Alternative strictly new window:
  # setsid firefox --new-window "${FOCUS_TABS[@]}" >/dev/null 2>&1 &
  # Alternative private:
  # setsid firefox --private-window "${FOCUS_TABS[@]}" >/dev/null 2>&1 &
}

# Launch Obsidian only if not already running; skip silently if not installed
launch_obsidian() {
  if command -v obsidian >/dev/null 2>&1; then
    # Only launch if no existing process with exact name 'obsidian'
    if ! pgrep -x obsidian >/dev/null 2>&1; then
      setsid obsidian >/dev/null 2>&1 &
    fi
  fi
}

if [ -f "$FOCUS_FLAG" ]; then
  # Focus mode is active, turn it off: restart apps
  notify-send "Focus Mode Disabled" "I guess it's playtime" >/dev/null 2>&1
  pkill -f discord
  pkill -f signal-desktop
  sleep 1
  setsid discord >/dev/null 2>&1 &
  setsid signal-desktop >/dev/null 2>&1 &
  rm -f "$FOCUS_FLAG"
else
  # Focus mode is inactive, turn it on: kill apps and start focus tools
  notify-send "Focus Mode Enabled" "Get to work lil bro" >/dev/null 2>&1
  playerctl --no-messages pause
  pkill -f discord
  pkill -f signal-desktop
  touch "$FOCUS_FLAG"

  # Start focus applications
  launch_obsidian
  launch_focus_browser

  # Optional: persistent kill loop
  while [ -f "$FOCUS_FLAG" ]; do
    pkill -f discord
    pkill -f signal-desktop
    sleep 15
  done &
fi
