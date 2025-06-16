#!/bin/bash

CONFIG_FOLDERS=(hypr kitty nvim waybar wofi obs-studio fastfetch Vencord dunst swappy)
HOME_FOLDERS=(.themes .icons .mozilla)
HOME_FILES=(.zshrc .p10k.zsh)

BACKUP_DIR="$HOME/Default config"

mkdir -p "$BACKUP_DIR"

# Function to prompt user and move folder/file
prompt_and_move() {
    local item=$1
    local dest=$2
    read -r -p "Apply $item config? (Y/n) " response
    response=${response,,} # tolower
    if [[ "$response" == "n" ]]; then
        echo "Skipping $item"
    else
        if [ -e "$dest/$item" ]; then
            echo "Backing up existing $item to $BACKUP_DIR"
            mv "$dest/$item" "$BACKUP_DIR/"
        fi
        echo "Moving $item to $dest"
        mv "$item" "$dest/"
    fi
}

# Move config folders to ~/.config
for folder in "${CONFIG_FOLDERS[@]}"; do
    if [ -d "$folder" ]; then
        prompt_and_move "$folder" "$HOME/.config"
    fi
done

# Move folders to home directory
for folder in "${HOME_FOLDERS[@]}"; do
    if [ -d "$folder" ]; then
        prompt_and_move "$folder" "$HOME"
    fi
done

# Move files to home directory
for file in "${HOME_FILES[@]}"; do
    if [ -f "$file" ]; then
        prompt_and_move "$file" "$HOME"
    fi
done

# Delete README.md if exists
if [ -f "README.md" ]; then
    echo "Deleting README.md"
    rm "README.md"
fi

# Make scripts inside hypr/scripts executable if hypr folder copied
if [ -d "$HOME/.config/hypr/scripts" ]; then
    echo "Making scripts in hypr/scripts executable"
    chmod +x "$HOME/.config/hypr/scripts/"*
fi
# Offer to install and/or change shell to zsh
if ! command -v zsh >/dev/null 2>&1; then
    echo "zsh is not installed."
    read -r -p "Would you like to install zsh? (Y/n) " install_zsh
    install_zsh=${install_zsh,,}
    if [[ "$install_zsh" != "n" ]]; then
        # Detect package manager and install zsh
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install zsh -y
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -Syu zsh --noconfirm
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install zsh -y
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper install zsh -y
        elif command -v xbps-install >/dev/null 2>&1; then
            sudo xbps-install -Sy zsh
        else
            echo "Could not detect package manager. Please install zsh manually."
        fi
    else
        echo "Skipping zsh installation."
    fi
fi

# Recommendations in bold green
echo -e "\033[1;32m"
echo "Recommendation:"
echo "- Start Firefox once after installation."
echo "- Change the monitor config name and refresh rate to your preferred settings in ac.conf and battery.conf."
echo "- Use the Windows+B keybinding to switch between AC and battery profiles."
echo "- Place your preferred wallpapers in \$HOME/Pictures/Wallpapers/hypr."
echo "- Use the Windows+I keybinding to switch between wallpapers."
echo "- Make sure your wallpapers are PNG files."
echo -e "\033[0m"
