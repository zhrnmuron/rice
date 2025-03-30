#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to print messages
print_message() {
    echo -e "\n\033[1;32m$1\033[0m\n"
}

# Update system and install prerequisites
print_message "Updating system and installing prerequisites..."
sudo pacman -Syu --noconfirm
sudo pacman -S base-devel git --noconfirm

# Install yay if not installed
if ! command -v yay &> /dev/null; then
    print_message "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    print_message "yay is already installed!"
fi

# Define packages to install (edit this section to add your packages)
PACKAGES=(
    # Add your packages here, e.g.:
    "firefox"
    "vlc"
    "neovim"
    "nwg-look"
    "hyprland"
    "hyprpolkitagent"
    "wofi"
    "waybar"
    "qbittorrent"
    "obs-studio"
    "pipewire"
    "pavucontrol"
    "wpctl"
    "brightnessctl"
    "playerctl"
    "nvidia"
    "yazi"
    "zsh"
    "fastfetch"
    "ark"
    "kitty"
    "dunst"
    "thunar"
    "hyprpaper"
    "imv"
    "btop"
)

# Install packages using yay
if [ ${#PACKAGES[@]} -eq 0 ]; then
    print_message "No packages specified. Please edit the script and add packages to the PACKAGES array."
else
    print_message "Installing packages with yay..."
    for package in "${PACKAGES[@]}"; do
        print_message "Installing $package..."
        yay -S "$package" --noconfirm --needed
    done
fi

print_message "All packages installed successfully!"

# Install NvChad for Neovim
print_message "Installing NvChad for Neovim..."

# Ensure Neovim is installed
if ! command -v nvim &> /dev/null; then
    print_message "Neovim is not installed. Installing it now..."
    sudo pacman -S neovim --noconfirm
fi

# Remove old Neovim configuration if it exists (optional)
if [ -d "$HOME/.config/nvim" ]; then
    print_message "Removing old Neovim configuration..."
    mv ~/.config/nvim ~/.config/nvim-old-$(date +%s)
fi

# Clone NvChad repository and initialize it
print_message "Cloning NvChad repository..."
git clone https://github.com/NvChad/starter ~/.config/nvim --depth 1

print_message "Starting Neovim to install NvChad plugins..."
nvim +PackerSync +qall

print_message "NvChad installation complete! You can now use Neovim with NvChad."

# Ask user if they want to install NVIDIA drivers
read -p "Do you want to install NVIDIA drivers? (y/n): " INSTALL_NVIDIA

if [[ "$INSTALL_NVIDIA" == "y" || "$INSTALL_NVIDIA" == "Y" ]]; then
    print_message "Installing NVIDIA drivers..."

    # Install NVIDIA drivers and utilities using yay
    yay -S nvidia-dkms nvidia-settings libxnvctrl lib32-nvidia-utils libvdpau opencl-nvidia lib32-opencl-nvidia --noconfirm

    # Add kernel modules for NVIDIA DRM KMS in mkinitcpio.conf
    print_message "Configuring kernel modules for NVIDIA DRM KMS..."
    sudo sed -i '/^MODULES=/ s/(/(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf

    # Regenerate initramfs to apply changes
    sudo mkinitcpio -P

    # Configure GRUB bootloader with NVIDIA DRM parameters
    print_message "Adding NVIDIA DRM parameters to GRUB configuration..."
    sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ nvidia_drm.modeset=1"/' /etc/default/grub

    # Update GRUB configuration file
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    # Create modprobe configuration file for NVIDIA DRM modeset
    print_message "Creating modprobe configuration for NVIDIA DRM modeset..."
    echo 'options nvidia_drm modeset=1' | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null

    print_message "NVIDIA driver installation complete! Please reboot your system to apply changes."
else
    print_message "Skipping NVIDIA driver installation."
fi

print_message "Script execution complete!"
