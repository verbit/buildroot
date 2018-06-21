OOTFS=$1
BOOT=$2
#mount /dev/mmblck0p3 /mnt
#rm -rf /broot/*
#tar xzf $ROOTFS
#unmount /broot

CURRENT_DEV=`grep -o 'root=[^ ]*' /proc/cmdline | cut -d '=' -f2`
echo "current device is $CURRENT_DEV"
[[ $CURRENT_DEV = /dev/mmcblk0p2 ]] && TARGET_DEV="/dev/mmcblk0p3" || TARGET_DEV="/dev/mmcblk0p2"
echo "target device is $TARGET_DEV"

echo "upgrade with $ROOTFS"
#dd if=$ROOTFS of=$TARGET_DEV bs=64K conv=fsync

BOOT_TEMP=`mktemp -d`
tar -xzf $BOOT -C $BOOT_TEMP
echo "contents in $BOOT_TEMP:"
ls $BOOT_TEMP
rm -rf $BOOT_TEMP



