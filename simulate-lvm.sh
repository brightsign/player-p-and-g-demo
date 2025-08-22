#!/bin/bash
# Simulate the exact LVM write/read process

echo "=== Simulating LVM Write/Read Process ==="
echo

if [ ! -f "ext_mon.squashfs" ]; then
    echo "Error: ext_mon.squashfs not found"
    exit 1
fi

IMAGE_SIZE=$(stat --format=%s ext_mon.squashfs)
IMAGE_SIZE_PAGES=$(((IMAGE_SIZE + 4095) / 4096))
VOLUME_SIZE=$(((IMAGE_SIZE + 4096 + 511) / 512 * 512))

echo "File size: $IMAGE_SIZE bytes"
echo "Pages: $IMAGE_SIZE_PAGES pages" 
echo "Volume size: $VOLUME_SIZE bytes"
echo "File size modulo 4096: $((IMAGE_SIZE % 4096))"
echo

# Simulate writing to LVM volume
echo "1. Simulating LVM write process:"
echo "   (cat file && dd if=/dev/zero bs=4096 count=1) > volume"
(cat ext_mon.squashfs && dd if=/dev/zero bs=4096 count=1 2>/dev/null) > simulated_volume.img
echo "   Simulated volume size: $(stat --format=%s simulated_volume.img) bytes"
echo

# Simulate reading from LVM volume  
echo "2. Reading from simulated volume (first method - by pages):"
dd if=simulated_volume.img bs=4096 count=$IMAGE_SIZE_PAGES 2>/dev/null | sha256sum | cut -c1-64
echo

echo "3. Reading from simulated volume (second method - exact bytes):"
dd if=simulated_volume.img bs=1 count=$IMAGE_SIZE 2>/dev/null | sha256sum | cut -c1-64
echo

echo "4. Original file SHA256 for comparison:"
sha256sum ext_mon.squashfs | cut -c1-64
echo

# Cleanup
rm -f simulated_volume.img

echo "The issue is likely that reading by pages from the LVM volume"
echo "includes some zero padding at the end of the last partial page."