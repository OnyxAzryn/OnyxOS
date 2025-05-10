#!/bin/bash

set -ouex pipefail

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
dnf install -y code docker-ce gcc libvirt libvirt-client libvirt-nss virt-manager virt-viewer wireshark zsh

# Uninstall Firefox, use the Flatpak instead
dnf remove -y firefox firefox-langpacks

# Disable VSCode repository
sed -i "1,/enabled=1/{s/enabled=1/enabled=0/}" /etc/yum.repos.d/vscode.repo

# Install the CachyOS Kernel
dnf remove -y kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt
dnf -y copr enable bieszczaders/kernel-cachyos-lto
dnf install -y kernel-cachyos-lto
dnf -y copr disable bieszczaders/kernel-cachyos-lto

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

# Branding
if [[ "${IMAGE}" =~ cosmic|ucore ]]; then
    tee /usr/share/ublue-os/image-info.json <<'EOF'
{
  "image-name": "",
  "image-flavor": "",
  "image-vendor": "OnyxAzryn",
  "image-ref": "ostree-image-signed:docker://ghcr.io/onyxazryn/onyxos",
  "image-tag": "",
  "base-image-name": "",
  "fedora-version": ""
}
EOF
fi

BASE_IMAGE="${BASE_IMAGE##*/}"

case "${IMAGE}" in
"bazzite"* | "bluefin"*)
    base_image="silverblue"
    ;;
"aurora"*)
    base_image="kinoite"
    ;;
"cosmic"*)
    #shellcheck disable=2153
    base_image="base-atomic"
    ;;
"ucore"*)
    base_image="coreos"
    ;;
esac

image_flavor="main"
if [[ "$IMAGE" =~ nvidia|bazzite($|-beta$) ]]; then
    image_flavor="nvidia"
fi

# Branding
cat <<<"$(jq ".\"image-name\" |= \"OnyxOS\" |
              .\"image-flavor\" |= \"${image_flavor}\" |
              .\"image-vendor\" |= \"OnyxAzryn\" |
              .\"image-ref\" |= \"ostree-image-signed:docker://ghcr.io/onyxazryn/onyxos\" |
              .\"image-tag\" |= \"${IMAGE}\" |
              .\"base-image-name\" |= \"${base_image}\" |
              .\"fedora-version\" |= \"$(rpm -E %fedora)\"" \
    </usr/share/ublue-os/image-info.json)" \
>/tmp/image-info.json
cp /tmp/image-info.json /usr/share/ublue-os/image-info.json

if [[ "$IMAGE" =~ bazzite ]]; then
    sed -i 's/image-branch/image-tag/' /usr/libexec/bazzite-fetch-image
fi

# OS Release File for Cosmic
if [[ "$IMAGE" =~ cosmic ]]; then
    sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Bluefin $(echo "${IMAGE^}" | cut -d - -f1) (Version: ${VERSION})\"|" /usr/lib/os-release
    sed -i "s/^VARIANT_ID=.*/VARIANT_ID=${IMAGE}/" /usr/lib/os-release
    sed -i "s/^NAME=.*/NAME=\"${IMAGE^} Atomic\"/" /usr/lib/os-release
    sed -i "s/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME=\"${IMAGE^}\"/" /usr/lib/os-release
    sed -i "s/^ID=fedora/ID=${IMAGE^}\nID_LIKE=\"fedora\"/" /usr/lib/os-release
    sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" /usr/lib/os-release
else
    sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"$(echo "${IMAGE^}" | cut -d - -f1) (Version: ${VERSION})\"|" /usr/lib/os-release
fi

sed -i "s|^VERSION=.*|VERSION=\"${VERSION} (FROM Universal Blue $(echo "${BASE_IMAGE^}" | cut -d - -f1))\"|" /usr/lib/os-release
sed -i "s|^OSTREE_VERSION=.*|OSTREE_VERSION=\"${VERSION}\"|" /usr/lib/os-release
sed -i "s|^IMAGE_ID=.*|IMAGE_ID=\"${IMAGE}\"|" /usr/lib/os-release || (echo "IMAGE_ID=\"${IMAGE}\"" >>/usr/lib/os-release)
sed -i "s|^IMAGE_VERSION=.*|IMAGE_VERSION=\"${VERSION}\"|" /usr/lib/os-release || (echo "IMAGE_VERSION=\"${VERSION}\"" >>/usr/lib/os-release)
ln -sf /usr/lib/os-release /etc/os-release
