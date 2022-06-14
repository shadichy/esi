#!/bin/bash

WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
START_TIME=$(date +%s)
# Source config file
CFG_FILE="build.cfg"
. $CFG_FILE

root_image="root.img"
data_image="data.img"

# Process command line arguments
while [[ "$1" ]];do
	case $1 in
		-h|--help)
			echo "Usage: $0 [--help] [-b | --build <build image list (rootfs|data)>] [-r | --rootfs <root image>] [-d | --data <data image>] [-o | --output <output iso>] [-i | --noiso]"
			echo "Options:"
			echo "  -h, --help: Print this help message"
			echo "  -b, --build: Build the specified image"
			echo "  -r, --rootfs: Specify custom rootfs image"
			echo "  -d, --data:  Specify custom data image"
			exit 0
			;;
		-r|--rootfs=*)
			[[ "${1}" == *"="* ]] && root_image="${1#*=}" || root_image="$2"
			;;
		-d|--data=*)
			[[ "${1}" == *"="* ]] && data_image="${1#*=}" || data_image="$2"
			;;
		-o|--output=*)
			[[ "${1}" == *"="* ]] && output_iso="${1#*=}" || output_iso="$2"
			;;
		-i|--noiso)
			noiso="true"
			;;
		-b|--build=*)
			# Build the image rootfs and/or data image, separated by comma, e.g. -b rootfs,data, for each, run $WORKDIR/build_<rootfs|data>.sh
			[[ "${1}" == *"="* ]] && build_type="${1#*=}" || build_type="$2"
			for build_item in $(echo $build_type | tr "," "\n"); do
				if [ ! -f $WORKDIR/build_$build_item.sh ]; then
					echo "Error: $WORKDIR/build_$build_item.sh does not exist"
					exit 1
				fi
				echo "Building $build_item"
				$WORKDIR/build_${build_item}.sh ${build_item}_image
			done
			exit 0
			;;
	esac
	shift
done

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

if [ ! -f $root_image ]; then
	echo "No root image ($root_image) found at $WORKDIR, please get at least one from Shadichy!"
	exit 1
fi
echo "Preparing to build ExtOS iso"
# Check if there are any mountpoint inside /mnt
for i in $(mount | grep $WORKDIR/mounts | awk '{print $3}'); do
	umount -l $i
done

# Check if folder iso exist
if [ ! -d iso ]; then
	mkdir iso
fi


# Check if mountpoint folders exist
if [ ! -d $WORKDIR/mounts ]; then
	mkdir $WORKDIR/mounts
fi
if [ ! -d $WORKDIR/mounts/tmp ]; then
	mkdir $WORKDIR/mounts/tmp
fi

./build_rootfs.sh $root_image

./build_data.sh $data_image

if [[ $noiso != "true" ]]; then

	if [[ -z $output_iso ]]; then
		# Update build
		echo "Updating build"
		sed -i -e "s/\(BUILD_NO=*\).*/\1$(( BUILD_NO + 1 ))/" $CFG_FILE

		if [ "$(($(date +%s) - $LAST_BUILD))" -gt 604800 ]; then
			sed -i -e "s/\(MASTER=*\).*/\1$(( MASTER + 1 ))/" $CFG_FILE;
		else
			sed -i -e "s/\(MINUS=*\).*/\1$(( MINUS + 1 ))/" $CFG_FILE;
		fi

		sed -i -e "s/\(LAST_BUILD=*\).*/\1$(date +%s)/" $CFG_FILE
		output_iso="ExtOS-beta-v0.$MASTER.$MINUS-build$BUILD_NO-$ARCH.iso"
	fi

	# Create iso
	echo "Creating iso"
	. $CFG_FILE
	# mkisofs -o "$output_iso" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -T $WORKDIR/iso
	grub-mkrescue -V "EXTOS" -o "$output_iso" iso
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
	echo "File name: $WORKDIR/$output_iso"
	echo "File size: $(du -h $output_iso | awk '{print $1}')"
	echo " "

fi
