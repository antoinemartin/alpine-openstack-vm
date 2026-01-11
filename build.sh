#!/usr/bin/env sh
# cSpell: words nocloud genisoimage volid cidata subformat
set -eu

rm -rf build
mkdir -p build
cd build

CLOUD_CONFIG_FILE=${1:-cloud-config.yaml}
echo "Using cloud config file: $CLOUD_CONFIG_FILE"

wget https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/v0.13.3/alpine-make-vm-image \
&& echo 'f17ef4997496ace524a8e8e578d944f3552255bb  alpine-make-vm-image' | sha1sum -c \
|| exit 1
chmod +x ./alpine-make-vm-image

if command -v sudo >/dev/null 2>&1; then
    ELEVATE="sudo"
elif command -v doas >/dev/null 2>&1; then
    ELEVATE="doas"
else
    echo "Neither sudo nor doas found. This script requires root privileges."
    exit 1
fi

$ELEVATE ./alpine-make-vm-image \
    --image-format qcow2 \
    --image-size 1G \
    --repositories-file ../openstack/repositories \
    --packages "$(cat ../openstack/packages)" \
    --keys-dir ../openstack/keys \
    --script-chroot \
    alpine-openstack.qcow2 -- ../openstack/configure.sh "$CLOUD_CONFIG_FILE"

sha256sum alpine-openstack.qcow2 > SHA256SUMS
qemu-img convert alpine-openstack.qcow2 -O vhdx -o subformat=dynamic alpine-openstack.vhdx
(cd ../nocloud; genisoimage  -output ../build/seed.iso -volid CIDATA -joliet -rock user-data meta-data; )
sha256sum alpine-openstack.vhdx seed.iso >> SHA256SUMS
