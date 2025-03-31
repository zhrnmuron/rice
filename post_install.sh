#!/bin/bash

# Function to check for failure and log it
log_failure() {
    echo "$1 failed" >> failures.log
}

# Request sudo password upfront
echo "Requesting sudo access..."
sudo -v

# Install base-devel
echo "Installing base-devel..."
sudo pacman -Syu --needed base-devel || log_failure "base-devel installation"

# Install yay
echo "Installing yay..."
if ! git clone https://aur.archlinux.org/yay.git; then
    log_failure "yay cloning"
else
    cd yay || log_failure "cd yay"
    makepkg -si || log_failure "yay installation"
    cd ..
    rm -rf yay
fi

# Package categories
declare -A package_categories=(
    ["Essentials"]="git firefox vlc neovim nwg-look hyprland wofi waybar qbittorrent obs-studio wpctl brightnessctl playerctl yazi zsh fastfetch unzip unrar 7zip kitty thunar imv btop reflector xf86-video-intel"
    ["Fonts"]="ttf-font-awesome ttf-jetbrains-mono-nerd ttf-fira-code ttf-dejavu"
    ["Hyprland dependencies"]="xdg-desktop-portal-hyprland hyprpolkitagent grim slurp swappy hyprpaper dunst"
    ["Audio"]="pipewire pipewire-pulse pavucontrol"
    ["Neovim Dependencies"]="npm wl-clipboard"
    ["Bootloader stuff"]="grub efibootmgr os-prober"
    ["Virtual machine stuff"]="qemu virt-manager"
)

# Iterate through categories and ask for installation
for category in "${!package_categories[@]}"; do
    read -p "Do you want to install packages from the $category category? (yes/no): " install_category
    if [[ "$install_category" == "yes" ]]; then
        echo "Installing $category packages..."
        for package in ${package_categories[$category]}; do
            if ! sudo pacman -Syu --needed "$package"; then
                log_failure "$category package: $package installation"
            fi
        done
    fi
done

# Clone rice repository and move .config contents
echo "Cloning rice repository..."
if ! git clone https://github.com/zhrnmuron/rice rice; then
    log_failure "rice cloning"
else
    mkdir -p ~/.config
    cp -r rice/.config/* ~/.config/ || log_failure ".config copying"
    rm -rf rice
fi

# Download Juno Ocean theme and move contents to .themes
echo "Downloading Juno Ocean theme..."
mkdir -p ~/.themes
if ! git clone https://github.com/EliverLara/Juno.git juno-ocean; then
    log_failure "Juno Ocean cloning"
else
    cp -r juno-ocean/* ~/.themes/ || log_failure ".themes copying"
    rm -rf juno-ocean
fi

# Set Juno Ocean as default theme (example for GTK apps)
echo "Setting Juno Ocean as default theme..."
gsettings set org.gnome.desktop.interface gtk-theme "Juno-Ocean" || log_failure "setting Juno Ocean theme"

# Ask about NVIDIA drivers installation
read -p "Do you want to install NVIDIA drivers? (yes/no): " install_nvidia
if [[ "$install_nvidia" == "yes" ]]; then
    echo "Installing NVIDIA drivers..."
    sudo pacman -Syu --needed nvidia || log_failure "NVIDIA drivers installation"

    # Update GRUB config for NVIDIA drivers
    echo "Updating GRUB config..."
    sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/ s/"[^"]*"/"quiet splash nvidia-drm.modeset=1"/' /etc/default/grub || log_failure "GRUB config update"
    sudo grub-mkconfig -o /boot/grub/grub.cfg || log_failure "GRUB update"

    # Modify mkinitcpio.conf if needed (per Arch Linux NVIDIA guide)
    echo "Modifying mkinitcpio.conf..."
    if ! grep -q 'MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)' /etc/mkinitcpio.conf; then
        sudo sed -i '/^MODULES=/ s/()/(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf || log_failure "mkinitcpio.conf modification"
        sudo mkinitcpio -P || log_failure "mkinitcpio update"
    fi
fi

# Retry failed steps if any exist in failures.log
if [[ -f failures.log ]]; then
    echo "The following steps failed:"
    cat failures.log

    read -p "Do you want to retry failed steps? (yes/no): " retry_failures
    if [[ "$retry_failures" == "yes" ]]; then
        while read -r failure; do
            case "$failure" in
                *base-devel*) sudo pacman -Syu --needed base-devel ;;
                *yay*) git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && cd .. && rm -rf yay ;;
                *rice*) git clone https://github.com/zhrnmuron/rice rice && cp -r rice/.config/* ~/.config/ && rm -rf rice ;;
                *Juno*) git clone https://github.com/EliverLara/Juno.git juno-ocean && cp -r juno-ocean/* ~/.themes/ && rm -rf juno-ocean ;;
                *NVIDIA*) sudo pacman -Syu --needed nvidia ;;
                *GRUB*) sudo grub-mkconfig -o /boot/grub/grub.cfg ;;
                *mkinitcpio*) sudo mkinitcpio -P ;;
                *) echo "$failure not recognized for retry." ;;
            esac
        done < failures.log
        rm failures.log  # Clear the failure log after retrying steps.
    fi
else
    echo "All steps completed successfully!"
fi

exit 0
