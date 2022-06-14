#!/bin/bash

if [ ! -d $WORKDIR/mounts/root ]; then
	mkdir $WORKDIR/mounts/root
fi
# Create a copy of root image
echo "Creating a new copy of root image"
dd if=$1 of=new_root.img status=progress
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
rsync -a --ignore-existing $WORKDIR/mounts/root/var/ $WORKDIR/mounts/tmp/var/

# Delete source
rm -rf $WORKDIR/mounts/root/var/*

# Create readonly image
echo "Creating readonly image"
mksquashfs $WORKDIR/mounts/root iso/root.sfs

# Cleanup
umount $WORKDIR/mounts/root
rm -rf new_root.img
