SYSUPGRADE=$1
mount -t ext4 /dev/mmcblk2 /mnt
echo "moving $SYSUPGRADE"
mv $SYSUPGRADE /mnt/sysupgrade.tar.gz
umount /mnt
reboot
