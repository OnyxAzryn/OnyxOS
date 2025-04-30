#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y zsh 
dnf5 remove -y kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

dnf5 -y copr enable bieszczaders/kernel-cachyos-lto
dnf5 install -y kernel-cachyos-lto
dnf5 -y copr disable bieszczaders/kernel-cachyos-lto

QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-cachyos-lto-(\d+)' | sed -E 's/kernel-cachyos-lto-//')"
dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

chmod 0600 /lib/modules/$QUALIFIED_KERNEL/initramfs.img


#### Example for enabling a System Unit File

systemctl enable podman.socket
