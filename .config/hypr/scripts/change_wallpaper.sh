#!/usr/bin/env bash

# --- Configurable Variables ---
WALLPAPER_DIR="$HOME/Pictures/Wallpapers/hypr/"
STATE_FILE="$HOME/.config/hypr/.wallpaper_index"
CONFIG_FILE="$HOME/.config/hypr/hyprpaper.conf"

# --- Robust Firefox profile detection ---
PROFILE_INI="$HOME/.mozilla/firefox/profiles.ini"
DEFAULT_PROFILE=$(awk -F= '/^\[Install/ {found=1} found && /^Default=/ {print $2; exit}' "$PROFILE_INI")
if [[ -z "$DEFAULT_PROFILE" ]]; then
    DEFAULT_PROFILE=$(awk -F= '/^Path=/ {print $2; exit}' "$PROFILE_INI")
fi
FIREFOX_PROFILE="$HOME/.mozilla/firefox/$DEFAULT_PROFILE"
FIREFOX_CHROME_IMG="$FIREFOX_PROFILE/chrome/img/amongus.png"
mkdir -p "$(dirname "$FIREFOX_CHROME_IMG")"


# --- Get monitor name (focused) ---
MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
if [[ -z "$MONITOR" ]]; then
    notify-send "Wallpaper script" "Could not detect monitor name."
    exit 1
fi

# --- Get sorted list of wallpapers ---
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
NUM_WALLPAPERS=${#WALLPAPERS[@]}
if [[ $NUM_WALLPAPERS -eq 0 ]]; then
    notify-send "Wallpaper script" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# --- Read last index, default to 0 ---
if [[ -f "$STATE_FILE" ]]; then
    INDEX=$(<"$STATE_FILE")
else
    INDEX=0
fi

# --- Get next wallpaper and increment index ---
WALLPAPER="${WALLPAPERS[$INDEX]}"
NEXT_INDEX=$(( (INDEX + 1) % NUM_WALLPAPERS ))
echo "$NEXT_INDEX" > "$STATE_FILE"

# --- Set wallpaper using hyprpaper IPC ---
hyprctl hyprpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper "$MONITOR,$WALLPAPER"
hyprctl hyprpaper unload unused

# --- Write to hyprpaper.conf for persistence ---
echo "preload = $WALLPAPER" > "$CONFIG_FILE"
echo "wallpaper = $MONITOR,$WALLPAPER" >> "$CONFIG_FILE"
echo "ipc = true" >> "$CONFIG_FILE"

# --- Symlink current wallpaper to Firefox new tab background as well as the current_background.png in the pictures folder, which is used for hyprlock ---
ln -sf "$WALLPAPER" "$FIREFOX_CHROME_IMG"
ln -sf "$WALLPAPER" "$HOME/Pictures/current_wallpaper.png"
notify-send "Wallpaper changed" "Desktop and Firefox new tab updated."

