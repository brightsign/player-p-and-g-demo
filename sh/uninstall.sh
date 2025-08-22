#!/bin/sh
# BrightSign Mon Extension Uninstall Script
# This script removes the monitoring extension from the BrightSign player

set -e

EXTENSION_NAME="mon"
EXTENSION_PATH="/var/volatile/bsext/ext_${EXTENSION_NAME}"

echo "BrightSign Mon Extension Uninstaller"
echo "===================================="
echo

# Check if extension is installed
if [ ! -d "$EXTENSION_PATH" ]; then
    echo "Extension not found at $EXTENSION_PATH"
    echo "Nothing to uninstall."
    exit 0
fi

echo "Extension found at: $EXTENSION_PATH"
echo

# Stop the extension services if they're running
echo "Stopping extension services..."
if [ -x "$EXTENSION_PATH/bsext_init" ]; then
    "$EXTENSION_PATH/bsext_init" stop || echo "Warning: Failed to stop services cleanly"
else
    echo "Warning: bsext_init script not found or not executable"
fi

# Wait a moment for services to stop
sleep 2

# Kill any remaining processes
echo "Ensuring all processes are stopped..."
killall prometheus 2>/dev/null || true
killall grafana-server 2>/dev/null || true

# Verify processes are stopped
if ps | grep -E "prometheus|grafana" | grep -v grep; then
    echo "Warning: Some processes may still be running"
    echo "You may need to manually kill them:"
    ps | grep -E "prometheus|grafana" | grep -v grep
fi

# Unmount the extension
echo "Unmounting extension..."
if mountpoint -q "$EXTENSION_PATH"; then
    umount "$EXTENSION_PATH" || echo "Warning: Failed to unmount $EXTENSION_PATH"
else
    echo "Extension not mounted"
fi

# Remove the mount point directory
echo "Removing extension directory..."
rmdir "$EXTENSION_PATH" 2>/dev/null || echo "Warning: Could not remove $EXTENSION_PATH"

# Remove dm-verity mapping if it exists
echo "Cleaning up dm-verity mapping..."
if [ -b "/dev/mapper/bsos-ext_${EXTENSION_NAME}-verified" ]; then
    veritysetup close "bsos-ext_${EXTENSION_NAME}-verified" || echo "Warning: Failed to close verity mapping"
fi

# Remove LVM volume
echo "Removing LVM volume..."
if [ -b "/dev/mapper/bsos-ext_${EXTENSION_NAME}" ]; then
    lvremove --yes "/dev/mapper/bsos-ext_${EXTENSION_NAME}" || echo "Warning: Failed to remove LVM volume"
    rm -f "/dev/mapper/bsos-ext_${EXTENSION_NAME}" 2>/dev/null || true
fi

echo
echo "Extension uninstallation completed."
echo "Please reboot the player for changes to take full effect:"
echo "  reboot"
echo