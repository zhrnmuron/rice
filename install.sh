#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root."
    exit 1
fi

# Partition variables
DISK="/dev/nvme0n1"
EFI="${DISK}p1"
SWAP="${DISK}p2"
ROOT="${DISK}p3"

echo "=== Partitioning and Formatting Drives ==="
# Wipe partitions (WARNING: destructive, only for /dev/nvme0n1)
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+512M -t 1:ef00 "$DISK"
sgdisk -n 2:0:+4G   -t 2:8200 "$DISK"
sgdisk -n 3:0:0     -t 3:8300 "$DISK"
partprobe "$DISK"

# Format partitions
mkfs.fat -F32 "$EFI"
mkswap "$SWAP"
mkfs.ext4 "$ROOT"

# Mount partitions
mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot
swapon "$SWAP"

echo "=== Pacstrap Package Selection ==="
echo "Choose package set:"
select pkgset in "Full" "Minimal"; do
    case $pkgset in
        Full)
            PKGS="base linux linux-firmware neovim sudo networkmanager fastfetch zsh git firefox vlc unzip unrar 7zip xf86-video-intel ttf-font-awesome ttf-jetbrains-mono-nerd ttf-fira-code ttf-dejavu qbittorrent pipewire pipewire-pulse pavucontrol xdg-desktop-portal-hyprland hyprpolkitagent grim slurp swappy hyprpaper dunst playerctl brightnessctl wpctl npm wl-clipboard obs-studio nwg-look wofi waybar nvidia mesa ark thunar yazi"
            break
            ;;
        Minimal)
            PKGS="base linux linux-firmware neovim sudo fastfetch zsh git firefox ttf-font-awesome ttf-jetbrains-mono-nerd ttf-fira-code ttf-dejavu npm wl-clipboard ark yazi"
            break
            ;;
    esac
done

pacstrap -K /mnt $PKGS

echo "=== Generating fstab ==="
genfstab -U /mnt >> /mnt/etc/fstab

echo "=== Configuring System in chroot ==="

arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

# Prompt for username
read -p "Enter username to create: " USERNAME
useradd -m -G wheel "$USERNAME"

# Set passwords
echo "Set password for root:"
passwd
echo "Set password for $USERNAME:"
passwd "$USERNAME"

# Enable wheel group sudo
sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers

# Install systemd-boot
bootctl install
cat <<BOOT > /boot/loader/loader.conf
default arch
timeout 0
console-mode max
editor no
BOOT

KERNEL_VERSION=$(ls /lib/modules | sort -V | tail -n1)
ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p3)

cat <<ENTRY > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw
ENTRY

# Copy dotfiles from rice (assumes script is in /rice)
RICE_SRC="/rice"
USER_HOME="/home/$USERNAME"
for item in .config .themes p10k.zsh .zshrc; do
    if [[ -e "$RICE_SRC/$item" ]]; then
        cp -rT "$RICE_SRC/$item" "$USER_HOME/$item"
        chown -R "$USERNAME:$USERNAME" "$USER_HOME/$item"
    fi
done

# Set default shell to zsh
chsh -s /usr/bin/zsh "$USERNAME"
EOF

echo "=== Updating Mirrorlist ==="
reflector --verbose -n 20 -p http --sort rate --save /etc/pacman.d/mirrorlist --country India --latest 200

echo "=== Installation Complete ==="
read -p "Reboot now? (y/N): " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    reboot
else
    echo "You may now exit or continue using the live environment."
fi
