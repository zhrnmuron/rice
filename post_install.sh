#!/bin/bash

# Function to check for failure and log it
log_failure() {
    echo "$1 failed" >> failures.log
}

# Backup current sudoers file and set sudo timeout to 120 minutes
echo "Backing up sudoers file and setting sudo timeout to 120 minutes..."
sudo cp /etc/sudoers /etc/sudoers.bak || log_failure "Sudoers backup"
echo "Defaults env_reset,timestamp_timeout=120" | sudo tee -a /etc/sudoers > /dev/null || log_failure "Setting sudo timeout"

# Request sudo password upfront
echo "Requesting sudo access..."
sudo -v

# Set pacman parallel downloads to 5
echo "Configuring pacman for parallel downloads..."
sudo sed -i 's/^#ParallelDownloads = [0-9]*/ParallelDownloads = 5/' /etc/pacman.conf || log_failure "Pacman parallel downloads configuration"

# Install reflector and configure mirrors
echo "Installing reflector and configuring mirrors..."
sudo pacman -S --noconfirm --needed reflector || log_failure "Reflector installation"
sudo reflector --verbose -n 20 -p http --sort rate --save /etc/pacman.d/mirrorlist --country India --latest 200 || log_failure "Reflector mirror configuration"

# Perform a full system update initially
echo "Performing initial system update..."
sudo pacman -Syu --noconfirm || log_failure "Initial system update"

# Install base-devel
echo "Installing base-devel..."
sudo pacman -S --noconfirm --needed base-devel || log_failure "base-devel installation"

# Install yay
echo "Installing yay..."
if ! git clone https://aur.archlinux.org/yay.git; then
    log_failure "yay cloning"
else
    cd yay || log_failure "cd yay"
    makepkg -si --noconfirm || log_failure "yay installation"
    cd ..
    rm -rf yay
fi

# Package categories
declare -A package_categories=(
    ["Essentials"]="git firefox vlc neovim nwg-look hyprland wofi waybar qbittorrent obs-studio wpctl brightnessctl playerctl yazi zsh fastfetch unzip unrar 7zip kitty thunar imv btop xf86-video-intel"
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
        if ! sudo pacman -S --noconfirm --needed ${package_categories[$category]}; then
            log_failure "$category package installation"
        fi
    fi
done

# Clone rice repository and move .config contents, .zshrc, and p10k.zsh to home directory
echo "Cloning rice repository..."
if ! git clone https://github.com/zhrnmuron/rice rice; then
    log_failure "rice cloning"
else
    mkdir -p ~/.config
    cp -r rice/.config/* ~/.config/ || log_failure ".config copying"
    cp rice/.zshrc ~ || log_failure ".zshrc copying"
    cp rice/p10k.zsh ~ || log_failure "p10k.zsh copying"
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
    sudo pacman -S --noconfirm --needed nvidia || log_failure "NVIDIA drivers installation"

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

# Restore original sudoers file after script completion
echo "Restoring original sudoers file..."
sudo mv /etc/sudoers.bak /etc/sudoers || log_failure "Restoring sudoers file"

# Retry failed steps if any exist in failures.log
if [[ -f failures.log ]]; then
    echo "The following steps failed:"
    cat failures.log

    read -p "Do you want to retry failed steps? (yes/no): " retry_failures
    if [[ "$retry_failures" == "yes" ]]; then
        while read -r failure; do
            case "$failure" in
                *base-devel*) sudo pacman -S --noconfirm --needed base-devel ;;
                *yay*) git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm && cd .. && rm -rf yay ;;
                *rice*) git clone https://github.com/zhrnmuron/rice rice && cp -r rice/.config/* ~/.config/ && cp rice/.zshrc ~ && cp rice/p10k.zsh ~ && rm -rf rice ;;
                *Juno*) git clone https://github.com/EliverLara/Juno.git juno-ocean && cp -r juno-ocean/* ~/.themes/ && rm -rf juno-ocean ;;
                *NVIDIA*) sudo pacman -S --noconfirm --needed nvidia ;;
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
