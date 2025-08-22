#!/bin/sh
# This install script is only useful during development.
set -xe
echo "Trying to unmount npu_gaze volume"
if [ -d '/var/volatile/bsext/ext_npu_gaze' ]; then
    umount /var/volatile/bsext/ext_npu_gaze
    rmdir /var/volatile/bsext/ext_npu_gaze
fi
if [ -b '/dev/mapper/bsos-ext_npu_gaze-verified' ]; then
    veritysetup close 'bsos-ext_npu_gaze-verified'
fi
if [ -b '/dev/mapper/bsos-ext_npu_gaze' ]; then
    lvremove --yes '/dev/mapper/bsos-ext_npu_gaze'
    rm -f '/dev/mapper/bsos-ext_npu_gaze'
fi
if [ -b '/dev/mapper/bsos-tmp_npu_gaze' ]; then
    lvremove --yes '/dev/mapper/bsos-tmp_npu_gaze'
    rm -f '/dev/mapper/bsos-tmp_npu_gaze'
fi
lvcreate --yes --size 35250176b -n 'tmp_npu_gaze' bsos
echo Writing image to tmp_npu_gaze volume...
(cat ext_npu_gaze.squashfs && dd if=/dev/zero bs=4096 count=1) > /dev/mapper/bsos-tmp_npu_gaze
check="`dd 'if=/dev/mapper/bsos-tmp_npu_gaze' bs=4096 count=8605|sha256sum|cut -c-64`"
if [ "${check}" != "5b339f0cacca51572e39a24fc0f9b77017d378aa26bab423b6fb899d32dbd7aa" ]; then
    echo "VERIFY FAILURE for tmp_npu_gaze volume"
    lvremove --yes '/dev/mapper/bsos-tmp_npu_gaze' || true
    exit 4
fi
lvrename bsos 'tmp_npu_gaze' 'ext_npu_gaze'
