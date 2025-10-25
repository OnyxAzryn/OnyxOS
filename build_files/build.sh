#!/bin/bash

set -ouex pipefail

# Install the CachyOS Kernel
dnf remove -y kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
dnf -y copr enable bieszczaders/kernel-cachyos-lto
dnf install -y kernel-cachyos-lto kernel-cachyos-lto-devel-matched
dnf -y copr disable bieszczaders/kernel-cachyos-lto

# Add the VSCode repository
tee /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# Install cosmic
dnf install -y install @cosmic-desktop

# Install required packages
dnf install -y code gcc libvirt libvirt-client libvirt-nss virt-manager virt-viewer wireshark zsh

# Install ROCm
dnf install -y rocm-clinfo rocm-hip rocm-opencl rocminfo

# Uninstall Firefox, use the Flatpak instead
dnf remove -y firefox firefox-langpacks

# Disable VSCode repository
sed -i "1,/enabled=1/{s/enabled=1/enabled=0/}" /etc/yum.repos.d/vscode.repo

# Install CachyOS Kernel Addons
dnf -y copr enable bieszczaders/kernel-cachyos-addons
dnf install -y cachyos-ksm-settings scx-manager scx-scheds
dnf -y copr disable bieszczaders/kernel-cachyos-addons

# Generate initramfs
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-cachyos-lto-(\d+)' | sed -E 's/kernel-cachyos-lto-//')"
dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 /lib/modules/$QUALIFIED_KERNEL/initramfs.img

# Enable Podman
systemctl enable podman.socket
