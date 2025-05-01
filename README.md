# OnyxOS
This is a customized atomic image based off of cosmic-atomic-main from the Universal Blue project. It includes the CachyOS LTO Kernel along with some additional packages and tweaks.

## Important Notices
- This image does not currently support Secure Boot, as the CachyOS LTO Kernel is unsigned
- There may be frequent changes to the composition of this image as new requirements are discovered

## Usage
1. Download and install the latest [Fedora COSMIC Atomic](https://fedoraproject.org/atomic-desktops/cosmic/) image
2. Rebase to the unsigned image using the following command:
```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/onyxazryn/onyxos:latest
```
3. Rebase to the signed version of the image using the following command:
```
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/onyxazryn/onyxos:latest
```

## Resources
- [Universal Blue Images](https://github.com/ublue-os/main)
- [CachyOS Kernel LTO Copr](https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos-lto)
- [CachyOS Kernel Addons Copr](https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos-addons/)
