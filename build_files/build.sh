#!/bin/bash

set -ouex pipefail

# Install the CachyOS Kernel
dnf remove -y kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra dracut
dnf -y copr enable bieszczaders/kernel-cachyos-lto
setsebool -P domain_kernel_load_modules on
dnf install -y kernel-cachyos-lto
dnf -y copr disable bieszczaders/kernel-cachyos-lto
dnf install -y bootc ostree plymouth plymouth-plugin-label plymouth-plugin-two-step plymouth-scripts plymouth-system-theme plymouth-theme-spinner rpm-ostree

# Add the VSCode repository
tee /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# Install required packages
dnf install -y @cosmic-desktop code gcc wireshark zsh

# Uninstall Firefox, use the Flatpak instead
dnf remove -y firefox firefox-langpacks

# Disable VSCode repository
sed -i "1,/enabled=1/{s/enabled=1/enabled=0/}" /etc/yum.repos.d/vscode.repo

# Install CachyOS Kernel Addons
dnf -y copr enable bieszczaders/kernel-cachyos-addons
dnf install -y scx-manager scx-scheds
dnf -y copr disable bieszczaders/kernel-cachyos-addons

# Clean packages
dnf clean all

# Generate initramfs
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-cachyos-lto-(\d+)' | sed -E 's/kernel-cachyos-lto-//')"
dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 /lib/modules/$QUALIFIED_KERNEL/initramfs.img

# Enable Podman
systemctl enable podman.socket
