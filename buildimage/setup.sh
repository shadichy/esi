#!/bin/bash
WORKDIR=$(cd $(dirname $0); pwd)
START_TIME=$(date +%s)
# Source config file
CFG_FILE="build.cfg"
. $CFG_FILE

delfile () {
	# $1 is directory
	# $2 is file/folder name
	if [ -d $1 ]; then
		rm -rf $1/$2
	fi
}
# Check for sudo
if [ ! $(id -u) -eq 0 ]; then
	echo "Build failed: Root required"
	exit 1
fi
echo "Root access granted"

if [ ! -f root.img ]; then
	echo "No root image (root.img) found at $WORKDIR, please get at least one from Shadichy!"
	exit 1
fi
echo "Preparing to build ExtOS iso"
# Clean up before running
umount -l /dev/loop*
losetup -d /dev/loop*
# Check if there are any mountpoint inside /mnt
for i in $(mount | grep $WORKDIR/mounts | awk '{print $3}'); do
	umount -l $i
done

# Check if mountpoint folders exist
if [ ! -d $WORKDIR/mounts ]; then
	mkdir $WORKDIR/mounts
fi
if [ ! -d $WORKDIR/mounts/root ]; then
	mkdir $WORKDIR/mounts/root
fi
if [ ! -d $WORKDIR/mounts/data ]; then
	mkdir $WORKDIR/mounts/data
fi

# Create a copy of root image
echo "Creating a new copy of root image"
dd if=root.img of=new_root.img status=progress
# Mount that copy
echo "Mounting new root image"
mount -o loop new_root.img $WORKDIR/mounts/root

# Remove files that are not needed
echo "Deleting unnecessary files"

cd $WORKDIR/mounts/root

xargs --arg-file="$WORKDIR/files" rm -rf
rm -rf usr/lib/modules/*/build

delfile usr/share/ibus/dicts $(ls | grep emo | grep -Ev "en|vi")
delfile usr/share/i18n/locales $(ls | grep -Ev "en|vi|translit|POSIX|iso")
delfile usr/share/locale $(ls -d -- */ | grep -Ev "en|vi")
delfile usr/share/qt/translations $(ls | grep -v "en")
delfile usr/share/unicode/cldr/*/* $(ls | grep -Ev "en|vi|root")

rm -rf .Trash-*
rm -rf var/lib/pacman
rm -rf var/lib/dkms
rm -rf var/home/extuser/.cache
rm -rf var/home/extuser/.bash_history
rm -rf var/cache/*
rm -rf var/tmp/*
rm -rf var/log/*
rm -rf root/.*

# Copy kernal n init
rm -rf $WORKDIR/iso/boot/vmlinuz
cp boot/vmlinuz-* $WORKDIR/iso/boot
mv $WORKDIR/iso/boot/vmlinuz-* $WORKDIR/iso/boot/vmlinuz

rm -rf $WORKDIR/iso/boot/*.img
cp boot/*.img $WORKDIR/iso/boot/
mv $WORKDIR/iso/boot/initramfs-*-fallback.img $WORKDIR/iso/boot/initramfs-preload.img
mv $(ls $WORKDIR/iso/boot/initramfs-*.img | grep -Evw "initramfs-preload.img") $WORKDIR/iso/boot/initramfs.img

rm -rf boot/*

cd $WORKDIR

# Check if folder iso exist
if [ ! -d iso ]; then
	mkdir iso
fi
# Remove prev readonly image
# Check if image exist
if [ -f iso/root.sfs ]; then
	rm -f iso/root.sfs
fi

echo "Proccessing data image" 
# Mount data image
# Check if image exist
if [ ! -f iso/data.img ]; then
	echo "Creating data image"
	dd if=/dev/zero of=iso/data.img bs=1M count=32 status=progress
	mkfs.ext4 -F iso/data.img
fi
mount -o loop iso/data.img $WORKDIR/mounts/data
cd $WORKDIR/mounts/data

# Modify data image
rm -rf $(ls -d -- */ | grep -Ev "log|tmp|cache")

cd $WORKDIR
rsync -a --ignore-existing $WORKDIR/mounts/root/var/ $WORKDIR/mounts/data/var/

# Delete source
rm -rf $WORKDIR/mounts/root/var/*

# Create readonly image
echo "Creating readonly image"
mksquashfs $WORKDIR/mounts/root iso/root.sfs

# Clean up
echo "Cleaning up"
# Unmount disk images
umount $WORKDIR/mounts/data

umount $WORKDIR/mounts/root
rm -rf new_root.img

# Update build
echo "Updating build"
sed -i -e "s/\(BUILD_NO=*\).*/\1$(( BUILD_NO + 1 ))/" $CFG_FILE

if [ "$(($(date +%s) - $LAST_BUILD))" -gt 604800 ]; then
	sed -i -e "s/\(MASTER=*\).*/\1$(( MASTER + 1 ))/" $CFG_FILE;
else
	sed -i -e "s/\(MINUS=*\).*/\1$(( MINUS + 1 ))/" $CFG_FILE;
fi

sed -i -e "s/\(LAST_BUILD=*\).*/\1$(date +%s)/" $CFG_FILE

# Create iso
echo "Creating iso"
. $CFG_FILE
# mkisofs -o "ExtOS-beta-v0.$MASTER.$MINUS-build$BUILD_NO-$ARCH.iso" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -T $WORKDIR/iso
grub-mkrescue -V "EXTOS" -o "ExtOS-beta-v0.$MASTER.$MINUS-build$BUILD_NO-$ARCH.iso" iso
END_TIME=$(date +%s)
# Done
HOUR=$((($END_TIME - $START_TIME))/3600)
MIN=$((($END_TIME - $START_TIME)%3600/60))
SEC=$((($END_TIME - $START_TIME)%60))
echo "Build complete in $HOUR:$MIN:$SEC"
echo "Finished!"
echo " "
echo "Build number: $BUILD_NO"
echo "Version: 0.$MASTER.$MINUS"
echo "Architecture: $ARCH"
echo "Build date: $(date)"
echo "File name: $WORKDIR/ExtOS-beta-v0.$MASTER.$MINUS-build$BUILD_NO-$ARCH.iso"
echo "File size: $(du -h ExtOS-beta-v0.$MASTER.$MINUS-build$BUILD_NO-$ARCH.iso | awk '{print $1}')"
echo " "

