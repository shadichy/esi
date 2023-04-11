#!/bin/bash

die() {
	printf "ERROR: %s\n" "$*"
	exit 1
}
# Check for sudo
[ "$(id -u)" = 0 ] || die "This requires root permission"

makedir() { [ -d "$1" ] || mkdir "$1"; }

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_TIME=$(date +%s)
# Source config file
CFG_FILE="build.cfg"
. $CFG_FILE

root_image="root.img"
data_image="data.img"

delfile() { [ -d "$1" ] && rm -rf "$1/$2"; }

# Process command line arguments
while [[ "$1" ]]; do
	case $1 in
	-h | --help)
		echo "Usage: $0 [--help] [-b | --build <build image list (rootfs|data)>] [-r | --rootfs <root image>] [-d | --data <data image>] [-o | --output <output iso>] [-i | --noiso]"
		echo "Options:"
		echo "  -h, --help: Print this help message"
		echo "  -b, --build: Build the specified image"
		echo "  -r, --rootfs: Specify custom rootfs image"
		echo "  -d, --data:  Specify custom data image"
		exit 0
		;;
	-r | --rootfs=*) [[ "${1}" == *"="* ]] && root_image="${1#*=}" || root_image="$2" ;;
	-d | --data=*) [[ "${1}" == *"="* ]] && data_image="${1#*=}" || data_image="$2" ;;
	-o | --output=*) [[ "${1}" == *"="* ]] && output_iso="${1#*=}" || output_iso="$2" ;;
	-i | --noiso) noiso="true" ;;
	-b | --build=*) # Build the image rootfs and/or data image, separated by comma, e.g. -b rootfs,data, for each, run $WORKDIR/build_<rootfs|data>.sh
		[[ "${1}" == *"="* ]] && build_type="${1#*=}" || build_type="$2"
		for build_item in $(tr "," "\n" <<<"$build_type"); do
			[ -f "$WORKDIR/build_$build_item.sh" ] || die "$WORKDIR/build_$build_item.sh does not exist"
			echo "Building $build_item"
			"$WORKDIR/build_${build_item}.sh" "${build_item}_image"
		done
		exit 0
		;;
	esac
	shift
done

[ -f "$root_image" ] || die "No root image ($root_image) found at $WORKDIR, please get at least one from Shadichy!"

echo "Preparing to build ExtOS iso"
# Check if there are any mountpoint inside /mnt
for i in $(mount | grep "$WORKDIR/mounts" | awk '{print $3}'); do
	umount -l "$i"
done

# Check if folder iso exist
makedir iso

# Check if mountpoint folders exist
makedir "$WORKDIR/mounts"
makedir "$WORKDIR/mounts/tmp"

./build_rootfs.sh "$root_image"

./build_data.sh "$data_image"

[ "$noiso" = "true" ] && exit 0

if [ ! "$output_iso" ]; then
	# Update build
	echo "Updating build"
	sed -i -e "s/\(BUILD_NO=*\).*/\1$((BUILD_NO + 1))/" $CFG_FILE

	if [ "$(($(date +%s) - LAST_BUILD))" -gt 604800 ]; then
		sed -i -e "s/\(MASTER=*\).*/\1$((MASTER + 1))/" $CFG_FILE
	else
		sed -i -e "s/\(MINUS=*\).*/\1$((MINUS + 1))/" $CFG_FILE
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
HOUR=$(((END_TIME - START_TIME) / 3600))
MIN=$(((END_TIME - START_TIME) % 3600 / 60))
SEC=$(((END_TIME - START_TIME) % 60))
cat <<EOF
Build complete in $HOUR:$MIN:$SEC
Finished!

Build number: $BUILD_NO
Version: 0.$MASTER.$MINUS
Architecture: $ARCH
Build date: $(date)
File name: $WORKDIR/$output_iso
File size: $(du -h "$output_iso" | awk '{print $1}')

EOF
