#!/bin/bash
# Quick fix to generate a working installation script

set -e

EXTENSION_NAME="mon"
IMAGE_FILE="ext_mon.squashfs"

# Check if squashfs exists
if [ ! -f "$IMAGE_FILE" ]; then
    echo "Error: $IMAGE_FILE not found. Please build the extension first."
    exit 1
fi

# Get file stats
IMAGE_SIZE=$(stat --format=%s "$IMAGE_FILE")
VOLUME_SIZE=$((IMAGE_SIZE + 4096))
SHA256=$(sha256sum "$IMAGE_FILE" | cut -c1-64)

echo "Creating fixed installation script..."
echo "Image size: $IMAGE_SIZE bytes"
echo "Volume size: $VOLUME_SIZE bytes"  
echo "SHA256: $SHA256"

# Create the fixed installation script
cat > ext_mon_install-lvm-fixed.sh << 'EOF'
#!/bin/sh
# BrightSign Mon Extension LVM Installation Script - FIXED
set -xe

EXTENSION_NAME="mon"
IMAGE_SIZE=$(stat --format=%s ext_mon.squashfs)
VOLUME_SIZE=$((${IMAGE_SIZE} + 4096))
SHA256=$(sha256sum ext_mon.squashfs | cut -c1-64)

echo "Installing BrightSign Mon Extension..."
echo "Image size: ${IMAGE_SIZE} bytes"
echo "Volume size: ${VOLUME_SIZE} bytes"
echo "SHA256: ${SHA256}"

# Volume names - CORRECTLY SET
MAPPER_VOL_NAME="ext_mon"
TMP_VOL_NAME="tmp_ext_mon"
MOUNT_NAME="ext_mon"

echo "Volume names:"
echo "  Mapper: ${MAPPER_VOL_NAME}"
echo "  Temp: ${TMP_VOL_NAME}"
echo "  Mount: ${MOUNT_NAME}"

# Cleanup existing volumes
echo "Trying to unmount ${EXTENSION_NAME} volume"
if [ -d "/var/volatile/bsext/${MOUNT_NAME}" ]; then
    umount "/var/volatile/bsext/${MOUNT_NAME}" || true
    rmdir "/var/volatile/bsext/${MOUNT_NAME}" || true
fi

# Remove dm-verity mapping
if [ -b "/dev/mapper/bsos-${MAPPER_VOL_NAME}-verified" ]; then
    veritysetup close "bsos-${MAPPER_VOL_NAME}-verified" || true
fi

# Remove old volumes
if [ -b "/dev/mapper/bsos-${MAPPER_VOL_NAME}" ]; then
    lvremove --yes "/dev/mapper/bsos-${MAPPER_VOL_NAME}" || true
    rm -f "/dev/mapper/bsos-${MAPPER_VOL_NAME}" || true
fi

if [ -b "/dev/mapper/bsos-${TMP_VOL_NAME}" ]; then
    lvremove --yes "/dev/mapper/bsos-${TMP_VOL_NAME}" || true
    rm -f "/dev/mapper/bsos-${TMP_VOL_NAME}" || true
fi

# Create new LVM volume with CORRECT NAME
echo "Creating LVM volume: ${TMP_VOL_NAME}"
lvcreate --yes --size ${VOLUME_SIZE}b -n "${TMP_VOL_NAME}" bsos

echo "Writing image to ${TMP_VOL_NAME} volume..."
(cat ext_mon.squashfs && dd if=/dev/zero bs=4096 count=1) > "/dev/mapper/bsos-${TMP_VOL_NAME}"

# Verify the image
echo "Verifying written image..."
image_size_pages=$((${IMAGE_SIZE}/4096))
check="`dd "if=/dev/mapper/bsos-${TMP_VOL_NAME}" bs=4096 count=${image_size_pages} 2>/dev/null | sha256sum | cut -c-64`"

if [ "${check}" != "${SHA256}" ]; then
    echo "VERIFY FAILURE for ${TMP_VOL_NAME} volume"
    echo "Expected: ${SHA256}"
    echo "Got: ${check}"
    lvremove --yes "/dev/mapper/bsos-${TMP_VOL_NAME}" || true
    exit 4
fi

echo "Verification successful!"

# Rename to final volume name
echo "Renaming ${TMP_VOL_NAME} to ${MAPPER_VOL_NAME}"
lvrename bsos "${TMP_VOL_NAME}" "${MAPPER_VOL_NAME}"

echo ""
echo "Installation complete!"
echo "Extension volume: /dev/mapper/bsos-${MAPPER_VOL_NAME}"
echo ""
echo "REBOOT REQUIRED: The extension will be automatically mounted after reboot."
echo "After reboot, check: ls -la /var/volatile/bsext/${MOUNT_NAME}/"
echo ""
EOF

chmod +x ext_mon_install-lvm-fixed.sh

echo ""
echo "✓ Fixed installation script created: ext_mon_install-lvm-fixed.sh"
echo ""
echo "This script has the correct volume names and will create:"
echo "  - LVM volume: bsos-ext_mon"
echo "  - Mount point: /var/volatile/bsext/ext_mon/"
echo ""
echo "Copy this to your player and run it:"
echo "  scp ext_mon_install-lvm-fixed.sh brightsign@player:/storage/sd/"
echo "  ssh brightsign@player 'cd /storage/sd && bash ext_mon_install-lvm-fixed.sh && reboot'"