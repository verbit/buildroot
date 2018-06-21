#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
# BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

cp ${BOARD_DIR}/config.txt ${BINARIES_DIR}/rpi-firmware/config.txt
cp ${BOARD_DIR}/cmdline.txt ${BINARIES_DIR}/rpi-firmware/cmdline.txt

for arg in "$@"
do
	case "${arg}" in
		--add-pi3-miniuart-bt-overlay)
		if ! grep -qE '^dtoverlay=' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
			echo "Adding 'dtoverlay=pi3-miniuart-bt' to config.txt (fixes ttyAMA0 serial console)."
			cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# fixes rpi3 ttyAMA0 serial console
dtoverlay=pi3-miniuart-bt
__EOF__
		fi
		;;
		--aarch64)
		# Run a 64bits kernel (armv8)
		sed -e '/^kernel=/s,=.*,=Image,' -i "${BINARIES_DIR}/rpi-firmware/config.txt"
		if ! grep -qE '^arm_control=0x200' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
			cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# enable 64bits support
arm_control=0x200
__EOF__
		fi

		# Enable uart console
		if ! grep -qE '^enable_uart=1' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
			cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# enable rpi3 ttyS0 serial console
enable_uart=1
__EOF__
		fi
		;;
		--gpu_mem_256=*|--gpu_mem_512=*|--gpu_mem_1024=*)
		# Set GPU memory
		gpu_mem="${arg:2}"
		sed -e "/^${gpu_mem%=*}=/s,=.*,=${gpu_mem##*=}," -i "${BINARIES_DIR}/rpi-firmware/config.txt"
		;;
	esac

done

rm -rf "${GENIMAGE_TMP}"

#dd if=/dev/zero of=${BINARIES_DIR}/overlay.ext4 bs=10M count=1
#mkfs.ext4 -F ${BINARIES_DIR}/overlay.ext4

# create rootfs ext4
mkdir -p $BINARIES_DIR/rootfs
cp $BINARIES_DIR/rootfs.squashfs $BINARIES_DIR/rootfs/
rm -rf $BINARIES_DIR/rootfs.ext4
$HOST_DIR/sbin/mkfs.ext4 -d $BINARIES_DIR/rootfs $BINARIES_DIR/rootfs.ext4 50M
rm -rf $BINARIES_DIR/rootfs/

# create initramfs cpio
#rm -rf $BINARIES_DIR/initramfs/
mkdir -p $BINARIES_DIR/initramfs/{bin,sbin,lib,usr/{bin,sbin}}
cp $TARGET_DIR/bin/busybox $BINARIES_DIR/initramfs/bin
#cp $TARGET_DIR/lib/libc.so $BINARIES_DIR/initramfs/lib
#cp -a $TARGET_DIR/lib/ld* $BINARIES_DIR/initramfs/lib
cp $BOARD_DIR/init $BINARIES_DIR/initramfs/

PWDIR=`pwd`
cd $BINARIES_DIR/initramfs
find . | cpio -H newc -o | lz4 -9 -l > ../initramfs.cpio.lz4
cd ..
rm -rf initramfs/
echo "pwd: $PWDIR"
cd $PWDIR

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${BOARD_DIR}/genimage_sqfs.cfg"

#rm -rf ${BINARIES_DIR}/overlay.ext4

rm -rf ${BINARIES_DIR}/boot
mkdir -p ${BINARIES_DIR}/boot
cp ${BOARD_DIR}/{cmdline.txt,config.txt} ${BINARIES_DIR}/boot
cp -r ${BINARIES_DIR}/{zImage,initramfs.cpio.lz4,overlays,*.dtb*,rpi-firmware/{bootcode.bin,fixup.dat,start.elf}} ${BINARIES_DIR}/boot

tar czf ${BINARIES_DIR}/sysupgrade.tar.gz -C ${BINARIES_DIR} boot/ rootfs.squashfs


exit $?
