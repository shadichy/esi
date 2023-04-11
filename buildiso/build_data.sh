#!/bin/bash

if [ ! -d $WORKDIR/mounts/data ]; then
	mkdir $WORKDIR/mounts/data
fi
# Remove prev readonly image
# Check if image exist
if [ -f iso/root.sfs ]; then
	rm -f iso/root.sfs
fi

echo "Proccessing data image" 
# Mount data image
# Check if image exist
if [ ! -f iso/$1 ]; then
	echo "Creating data image"
	dd if=/dev/zero of=iso/$1 bs=1M count=32 status=progress
	mkfs.ext4 -F iso/$1
fi
mount -o loop iso/$1 $WORKDIR/mounts/data
cd $WORKDIR/mounts/data

# Modify data image
rm -rf $(ls -d -- */ | grep -Ev "log|tmp|cache")

cd $WORKDIR
rsync -a --ignore-existing $WORKDIR/mounts/tmp/var/ $WORKDIR/mounts/data/var/

# Cleanup
umount $WORKDIR/mounts/data
