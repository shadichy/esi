#!/bin/bash

randstr() { tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 8 | head -n 1; }
ynwarn() { dbox --extra-button --extra-label "No" --no-label "Back" --yesno "Warning: $*" 0 0; }

mount_check() {
	unmount() { mountpoint -q "$*" && umount -R "$*"; }
	for dir in /mnt/*; do unmount -R "$dir"; done
	unmount /mnt
	free | awk '/^Swap:/ {exit !"$2"}' && swapoff -a
	for vg in $(vgs --noheadings -o vg_name); do vgchange -ay "$vg"; done
}

disklst() {
	unset devs
	for dev in $(lsblk -M -n -p -r -e 7,11,251 -o NAME); do
		[ "$(lsblk -n -r -o MOUNTPOINT "$dev")" ] && continue
		devsz=$(lsblk -d -n -r -o SIZE "$dev")
		devtp=$(lsblk -d -n -o TYPE "$dev")
		devfs=$(lsblk -d -n -r -o FSTYPE "$dev")
		devmp=" "
		hasmntpt=$(say "${MNT_LST[@]}" | grep -w "$dev")
		[ "$hasmntpt" ] && devmp=$(echo "$hasmntpt" | awk '{print "$2"}')
		devs+=("$dev"$'\t'"" "$devtp"$'\t'"$devfs"$'\t'"$devsz"$'\t'"$devmp")
	done
}

diskchoose() {
	local diskconfirm=0
	title="Partition the harddrive"

	listblk() {
		opt=$1
		shift
		lsblk -n -p -r -e 7,11,251 -o "$opt" "$@"
	}

	create_part() {
		while IFS= read -r f; do
			part_size=$(echo "$f" | awk '{print "$3"}')
			((${part_size%MiB} <= 4096)) && continue

			part_start=$(say "$f" | awk '{print "$1"}')
			part_end=$(say "$f" | awk '{print "$2"}')
			part_table_before=("$(listblk NAME "$d")")
			printf "fix\n" | parted ---pretend-input-tty "$d" mkpart "$part_type" ext4 "$part_start" "$part_size" || continue

			part_table_after=("$(listblk NAME "$d")")
			part_id=$(echo "${part_table_before[*]} ${part_table_after[*]}" | tr ' ' '\n' | sort | uniq -u)
			[ "$part_table" = "msdos" ] && ! printf "fix\n" | parted ---pretend-input-tty "$part_id" -name "$LABEL" && continue

			e2label "$part_id" "$LABEL"
			e2fsck -f "$part_id"
			MNT_LST=("$part_id /")
			diskconfirm=1
		done <<<"$(printf "fix\n" | parted ---pretend-input-tty "$d" unit MiB print free | grep "Free Space")"
	}

	while true; do
		disk=$(dbox --cancel-label "Exit to Menu" --menu "Disk/partition options" 0 0 0 \
			"Auto" "Automatically choosing disk and partition to install (alongside other operating systems)" \
			"Basic" "Select disk/partition(s) to install" \
			"Manual" "Customize disk/partition layout")
		case "$disk" in
		"Auto")
			for d in $(listblk NAME -d); do
				part_table=$(printf "fix\n" | parted ---pretend-input-tty "$d" print | grep "Partition Table" | awk '{print "$3"}')
				case "$part_table" in
				"gpt") part_type="$LABEL" ;;
				"msdos") part_type="primary" ;;
				*) continue ;;
				esac

				create_part
				[ "$(grep -w "/" <<<"${MNT_LST[@]}" | awk '{print "$2"}')" ] && break

				for p in $(listblk NAME "$d" | grep -vw "$d"); do
					[ "$(lsblk -n -r -o MOUNTPOINT "$p")" ] && continue

					part_fs=$(lsblk -d -n -r -o FSTYPE "$p")
					[[ "$part_fs" =~ "crypt".* ]] || [[ "$part_fs" =~ "swap".* ]] || [[ "$part_fs" =~ "LVM".* ]] || [[ "$part_fs" =~ "raid".* ]] || [[ -z "$part_fs" ]] && continue

					mount "$p" /mnt || continue

					if [ "$(df -m --output=avail /mnt | grep -v "Avail")" -lt 4096 ]; then
						umount /mnt
						continue
					fi

					umount /mnt
					partinmb=$(printf "fix\n" | parted ---pretend-input-tty "$p" unit MiB print | grep -w "1" | awk '{print "$3"}')
					printf "fix\n" | parted ---pretend-input-tty "$p" resizepart 1 $((${partinmb%MiB} - 4096)) || continue

					create_part
					[ $diskconfirm = 1 ] && return
				done
			done
			;;
		"Basic")
			simplediskman
			[ "$diskconfirm" = 1 ] && return
			;;
		"Manual")
			if dialog --backtitle "$BACKTITLE" --title "Manual partitioning" --yes-label "Use Terminal interface" --no-label "Use Command line interface" --yesno "Would you like to use the terminal interface or the command line interface?" 0 0; then
				advcd_diskman
				[ "$diskconfirm" = 1 ] && return
			fi
			clear
			saybr ""
			saybr ""
			saybr "\e[1;32mQuick guide:"
			saybr ""
			saybr "\e[1;33m### Physical Disk/Partition Management ###\e[0m"
			saybr "\e[1;36m"
			saybr "\tUse 'lsblk' to see the list of disks/partitions."
			saybr "\tUse 'fdisk', 'cfdisk', 'parted' commands or any CLI-based disk utilities to manage disks/partitions"
			saybr ""
			saybr "\e[1;33m### Logical Volume Management ###\e[0m"
			saybr "\e[1;36m"
			saybr "\tUse pvdisplay, pvcreate, pvremove commands to manage physical volumes"
			saybr "\tUse vgdisplay, vgcreate, vgremove commands to manage volume groups"
			saybr "\tUse lvdisplay, lvcreate, lvremove commands to manage logical volumes"
			saybr ""
			saybr "\e[1;33m### Encrypted Volume Management ###\e[0m"
			saybr "\e[1;36m"
			saybr "\tUse cryptsetup commands to manage encrypted volumes"
			saybr ""
			saybr "\e[0mType 'exit' after you have done all the jobs"
			saybr ""
			$SHELL
			advcd_diskman
			[ "$diskconfirm" = 1 ] && return
			;;
		*) menusel ;;
		esac
	done
}

append_comma() { sed -r 's/\s+\//, \//gm' <<<"$*"; }

simplediskman() {
	mount_check
	disklst

	if [ ! "${devs[*]}" ]; then
		errbox "No device is available to install"
		return 1
	fi

	while true; do
		devdisk=$(dbox --cancel-label "Back" --ok-label "Select" --menu "Select the disk/partition for ExtOS to be installed on. Note that the disk/partition you select will be erased, but not until you have confirmed the changes.\n\nSelect the disk in the list below:" 0 80 0 "${devs[@]}") || break

		devtype=$(lsblk -d -n -r -o TYPE "$devdisk")
		case "$devtype" in
		disk) dorpb="entire disk" ;;
		*) dorpb="partition" ;;
		esac

		dialog --backtitle "$BACKTITLE" --title "Confirm install on $devdisk" --yes-label "Confirm" --no-label "Back" --yesno "Are you sure you want to install ExtOS on the $dorpb $devdisk?\n\nThis will erase all data on the $devdisk, and cannot be UN_STAT." 0 0 || continue

		dbox --yesno "Swap is a partition that serves as overflow space for your RAM.\nSwap is not required for ExtOS to run, but it is recommended to use swap for better performance on low-end hardware or hibernation.\n\nDo you want to use swap?" 0 0
		useswp=$?

		case "$devtype" in
		"part")
			rootfsdev="$devdisk"
			# while true; do
			#	 if [ useencrypt != 1 ]; then
			#		 break
			#	 fi
			#	 if [ $(lsblk -d -n -r -o TYPE "$rootfsdev") = "crypt" ]; then
			#		 break
			#	 fi
			#	 parentnode="/dev/$(lsblk -d -n -r -o PKNAME "$rootfsdev")"
			#	 # for p in $(lsblk -p -n -r -o NAME "$parentnode" | grep -vw "$parentnode"); do
			#	 #	 if [ "$(parted -s "$p" print | grep -w "boot")" ]; then
			#	 #		 echo "boot at $p"
			#	 #	 fi
			#	 # done
			#	 cryptsetup luksFormat "$rootfsdev"
			#	 if [ $? != 0 ]; then
			#		 break
			#	 fi
			#	 randname=$(randstr)
			#	 cryptsetup luksOpen "$rootfsdev" "$randname"
			#	 rootfsdev="/dev/mapper/$randname"
			#	 break
			# done
			dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --infobox "Formatting $devdisk as ext4" 0 0

			if ! mkfs.ext4 -F -L EXTOS "$devdisk"; then
				dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --msgbox "Failed to format $devdisk" 0 0
				continue
			fi

			MNT_LST+=("$devdisk /")
			flagasboot() {
				parted -s "$devdisk" set 1 boot on && return
				dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --msgbox "Failed to set $devdisk as bootable" 0 0
				continue
			}

			case $BIOSMODE in
			"uefi")
				ESP=$(lsblk -o NAME,LABEL,PARTLABEL | grep -w "EFI" | awk '{print "$1"}')
				if [ "$ESP" ]; then
					MNT_LST+=("$ESP /boot/efi")
				else
					flagasboot
				fi
				;;
			"bios") flagasboot ;;
			esac
			;;
		"disk")
			dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --infobox "Creating GPT partition table on $devdisk" 0 0
			if ! parted -s "$devdisk" mklabel gpt; then
				dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --msgbox "Failed to create GPT partition table on $devdisk" 0 0
				continue
			fi

			dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --infobox "Creating EFI system partition" 0 0
			if ! parted -s "$devdisk" mkpart primary fat32 1 100M; then
				dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --msgbox "Failed to create EFI system partition on $devdisk" 0 0
				continue
			fi

			ESP=$(lsblk -n -r -p -o NAME "$devdisk" | grep -vw "$devdisk")
			parted -s "$devdisk" name 1 EFI
			parted -s "$devdisk" set 1 esp on
			parted -s "$ESP" set 1 boot on
			mkfs.fat -F32 -n EFI "$ESP"
			MNT_LST+=("$ESP /boot$([ "$BIOSMODE" = uefi ] && say /efi)")

			dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --infobox "Creating partition to install ExtOS" 0 0
			if ! parted -s "$devdisk" mkpart primary ext4 101M 100%; then
				dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --msgbox "Failed to create partition on $devdisk" 0 0
				continue
			fi

			rootfsdev=$(lsblk -n -r -p -o NAME "$devdisk" | tail -n 1)
			parted -s "$devdisk" name 2 EXTOS

			useencrypt() {
				if ! cryptsetup luksFormat "$rootfsdev"; then
					dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --msgbox "Failed to format $rootfsdev" 0 0
					continue
				fi
				randname=$(randstr)
				cryptsetup luksOpen "$rootfsdev" "$randname"
				rootfsdev="/dev/mapper/$randname"
			}

			uselvm() {
				if ! pvcreate "$rootfsdev"; then
					dialog --backtitle "$BACKTITLE" --title "Formatting $devdisk" --msgbox "Failed to create physical volume on $rootfsdev" 0 0
					continue
				fi
				randname=$(randstr)
				vgcreate "$randname" "$rootfsdev"
				lvcreate -l 100%FREE -n EXTOS "$randname"
				rootfsdev="/dev/mapper/$randname-EXTOS"
			}

			devsize=$(lsblk -d -n -r -b -o SIZE "$devdisk")
			if ((${devsize%MiB} >= 8589934592)); then
				haslvm=""
				if ((${devsize%MiB} >= 34359738368)); then
					haslvm="\"LVM\" \"Use LVM multiple sub-partition on installation disk/partition (for over 32gb partitions and disks)\" \
								\"LVM-on-Encrypt\" \"Use LVM multiple sub-partition on Encrypted installation disk/partition\""
				fi
				case "$(dbox --cancel-label "No" --menu "Do you want to use LVM and/or Encrypt the installation disk/partition?\n\nSelect the option in the list below:" 0 0 0 \
					"No" "Do not use LVM or Encrypt the installation disk/partition" \
					"Encrypt" "Encrypt the installation disk/partition" \
					"$haslvm")" in
				"LVM") uselvm ;;
				"Encrypt") useencrypt ;;
				"LVM-on-Encrypt")
					useencrypt
					uselvm
					;;
				esac
			fi
			mkfs.ext4 -F -L EXTOS "$rootfsdev"
			MNT_LST+=("$rootfsdev /")
			;;
		esac
		diskconfirm=1
		PRT_STAT="*"
		break
	done
}

listpvfree() {
	pvfreelist=("")
	while IFS= read -r line; do
		pvfreelist+=("\"$line\" \"$(pvs --noheadings -o pv_size,pv_free,pv_uuid "$line")\" off ")
	done <<<"$(pvs --noheadings -o pv_name | grep -vf <(vgs --noheadings -o pv_name))"
}

advcd_lvmpv() {
	while true; do
		pvlist=("")
		for pv in "${pvofvg[@]}"; do
			pvinfo="$(pvs --noheadings -o pv_size,pv_free,pv_uuid "$pv" | awk '{for (i=1; i<NF; i++) printf "$i" " \t"; print $NF}')"
			pvlist+=("$pv" "$pvinfo")
		done
		pvselect=$(dbox --cancel-label "Back" --extra-button --extra-label "Add" --ok-label "Select" --menu "Select the physical volume to manage\n" 0 80 0 "${pvlist[@]}")
		case $? in
		0) while true; do
			vg_grs=($(pvs --noheadings -o vg_name "$pvselect"))
			pvopts=$(dbox --cancel-label "Back" --menu "Physical Volume Infomation:\n\nPhysical Volume Name:$pvselect\nSize: $(pvs --noheadings -o pv_size "$pvselect")\nFree: $(pvs --noheadings -o pv_free "$pvselect")\nUUID: $(pvs --noheadings -o pv_uuid "$pvselect")\nVolume Group: $(append_comma "${vg_grs[*]}")\n\nSelect an option:" 0 80 0 \
				"Replace" "Replace this Physical Volume with a new one" \
				"Remove from VG" "Remove this Physical Volume from this Volume Group" \
				"Remove" "Completely remove this Physical Volume") || break

			case "$pvopts" in
			"Replace")
				ynwarn "Are you sure about replacin Physical Volume $pvselect with a new one?"
				case $? in
				1) continue ;;
				3) break ;;
				esac
				while true; do
					listpvfree
					pvnew=$(dbox --cancel-label "Back" --menu "Select the new Physical Volume to replace this one\n" 0 80 0 "${pvfreelist[@]}") || break

					vgchange -a n "$vgselect" &&
						pvmove "$pvselect" "$pvnew" &&
						vgchange -a y "$vgselect"
					sleep 3
					return
				done
				;;
			"Remove from VG")
				ynwarn "Are you sure about removing Volume Group $vgselect?"
				case $? in
				1) continue ;;
				3) break ;;
				esac
				vgchange -a n "$vgselect" &&
					pvmove "$pvselect" &&
					vgreduce "$vgselect" "$pvselect" &&
					vgchange -a y "$vgselect"
				sleep 3
				break
				;;
			"Remove")
				ynwarn "Are you sure about removing Volume Group $vgselect?"
				case $? in
				1) continue ;;
				3) break ;;
				esac
				vgchange -a n "$vgselect" &&
					pvmove "$pvselect" &&
					vgreduce "$vgselect" "$pvselect" &&
					pvremove "$pvselect" &&
					vgchange -a y "$vgselect"
				sleep 3
				break
				;;
			esac
		done ;;
		1) break ;;
		3)
			listpvfree
			pvselect=$(dbox --cancel-label "Back" --ok-label "Select" --checklist "Select the physical volume to add to this Volume Group\n" 0 80 0 "${pvfreelist[@]}") || continue
			vgextend "$vgselect" "$pvselect" && break
			errbox "Could not add the physical volume to the volume group.\n\nPlease check the volume group and try again."
			;;
		esac
	done
}
advcd_lvm() {
	while true; do
		#$(vgs --noheadings -o vg_name)
		# vg_pv="$(printf "%s," $(vgs --noheadings -o pv_name "$vgname"))"
		# vg_pv=${vg_pv%,}
		# vg_lv="$(printf "%s," $(vgs --noheadings -o lv_name "$vgname"))"
		# vg_lv=${vg_lv%,}
		# vginfo+=""$'\t'"$vg_pv"$'\t'"$vg_lv"
		# pvlist=$(pvs --noheadings -o pv_name)

		vglist=("")
		while IFS= read -r line; do
			vglist+=("$(awk '{print "$1"}' <<<"$line")" "$(awk '{for (i=2; i<NF; i++) printf "$i" " \t"; print $NF}' <<<"$line")")
		done <<<"$(vgs -o vg_name,vg_size,vg_free,vg_uuid --noheadings)"

		vgselect=$(dbox --cancel-label "Back" --extra-button --extra-label "Create" --ok-label "Select" --help-button --help-label "Done" --menu "Select the volume group to manage\n" 0 80 0 "${vglist[@]}")
		case $? in
		0)
			while true; do
				pvofvg=($(vgs --noheadings -o pv_name "$vgselect"))
				lvofvg=($(vgs --noheadings -o lv_name "$vgselect"))

				vgoption=$(dbox --cancel-label "Back" --menu "Volume Group Infomation:\n\nVolume Group Name: $vgselect Size: $(vgs --noheadings -o vg_size "$vgselect")\nFree: $(vgs --noheadings -o vg_free "$vgselect")\nUUID: $(vgs --noheadings -o vg_uuid "$vgselect")\nPhysical Volumes: $(append_comma "${pvofvg[*]}")\nLogical Volumes: $(append_comma "${lvofvg[*]}")\n\nSelect an option:" 0 80 0 \
					"Manage PV" "Manage Physical Volume attached to this Volume Group" \
					"Manage LV" "Manage Logical Volume on this Volume Group" \
					"Rename" "Rename this Volume Group" \
					"Remove" "Remove this Volume Group") || break

				case "$vgoption" in
				"Manage PV") advcd_lvmpv ;;
				"Manage LV") while true; do
					lvlist=("")
					for lv in "${lvofvg[@]}"; do
						lvinfo="$(lvs --noheadings -o lv_size,lv_free,lv_uuid "$lv" | awk '{for (i=1; i<NF; i++) printf "$i" " \t"; print $NF}')"
						lvlist+=("$lv" "$lvinfo")
					done

					lvselect=$(dbox --cancel-label "Back" --extra-button --extra-label "Remove" --ok-label "Rename" --menu "Select the physical volume to manage\n" 0 80 0 "${lvlist[@]}")
					case $? in
					0) while true; do
						newlvname=$(dbox --inputbox "Enter the new name for the logical partition" 0 0) || break

						if [ -z "$newlvname" ]; then
							errbox "You didn't entered the new name!"
							continue
						fi

						if lvs --noheadings -o lv_name | grep -q "$newlvname"; then
							errbox "The logical partition $newlvname already exists!"
							continue
						fi

						lvrename "$lvselect" "$newlvname"
					done ;;
					3)
						ynwarn "Are you sure about removing Logical Volume $vgselect/$lvselect?"
						case $? in
						1) continue ;;
						3) break ;;
						esac
						lvremove "$vgselect"/"$lvselect"
						sleep 3
						;;
					esac
					break
				done ;;
				"Rename") while true; do
					newvgname=$(dbox --inputbox "Enter the new name for the volume group" 0 0) || break

					if [ -z "$newvgname" ]; then
						errbox "You didn't entered the new name!"
						continue
					fi

					if vgs --noheadings -o vg_name | grep -q "$newvgname"; then
						errbox "The volume group $newvgname already exists!"
						continue
					fi

					vgchange -a n "$vgselect" &&
						vgrename "$vgselect" "$newvgname" &&
						vgchange -a y "$newvgname"
					sleep 3
					break
				done ;;
				"Remove")
					ynwarn "Are you sure about removing Volume Group $vgselect?"
					case $? in
					1) continue ;;
					3) break ;;
					esac
					vgchange -an "$vgselect" &&
						vgremove "$vgselect"
					sleep 3
					break
					;;
				*) break ;;
				esac
			done
			;;
		1) return 1 ;;
		2) return ;;
		3)
			listpvfree
			pvselect=$(dbox --cancel-label "Back" --ok-label "Create" --checklist "Select the physical volumes to add to the volume group\n" 0 80 0 "${pvfreelist[@]}") || continue
			newvgname=$(dbox --inputbox "Please enter the name of the new volume group" 0 0) || continue

			if [ ! "$newvgname" ]; then
				errbox "You didn't entered the name of the new volume group!"
				continue
			fi

			if vgs "$newvgname" >/dev/null 2>&1; then
				errbox "The volume group $newvgname already exists!"
				continue
			fi

			if vgcreate "$newvgname" "$pvselect"; then
				dbox --msgbox "Successfully created the volume group $newvgname"
				return
			fi

			errbox "Could not create the volume group $newvgname!"
			;;
		esac
	done
}

advcd_partopts() {
	while true; do
		xtraopt=""
		[[ "$devfstype" =~ "crypt".* ]] && xtraopt="\"Decrypt\" \"Mount Encrypted\""
		[ "$devtype" == "disk" ] && xtraopt="\"Manage\" \"Manage Volumes/Partitions\""
		[ "$devtype" == "lvm" ] || [[ "$devfstype" =~ "LVM".* ]] && xtraopt="\"Manage LVM\" \"Manage LVM physical volumes, logical volumes, and volume groups\""

		case "$(dbox --cancel-label "Back" --menu "${devtype^^} $devdisk\nType: $devtype\n$dorpa\nSize: $(lsblk -d -n -r -o SIZE "$devdisk")\n\nChoose an action:" 0 0 0 \
			"Mountpoint" "Use $dorpb as " \
			"Format" "Change filesystem of $dorpb" \
			$xtraopt \
			$lvmopt)" in
		"Mountpoint") while true; do
			mntpt=$(dbox --cancel-label "Back" --menu "Choose mountpoint for $devtype $devdisk:\n\nNote: everything except '/' and '/boot' are optional" 0 0 0 \
				"/" "This is where the base system will be installed" \
				"/boot" "Needed for UEFI/LVM(bios/mbr)/encryption" \
				"/boot/efi" "(UEFI) EFI System partition" \
				"/home" "Userspace data will be saved here (not apply for Frugal Installation)" \
				"/usr" "App data will be stored here (not apply for Frugal Installation)" \
				"/etc" "App Configurations will be stored here (not apply for Frugal Installation)" \
				"/root" "Userspace data for root/admin will be stored here (not apply for Frugal Installation)" \
				"/var" "Stores app data, must be mounted as read-write (not apply for Frugal Installation)" \
				"/data" "(Frugal only) Data partition, the same as '/var' partition in normal installation" \
				"/overlay" "(Frugal only) Overlay partition, for storing overlay data" \
				"swap" "Virtual memory partition") || break

			ynwarn "All data on ${devtype^} $devdisk will be erased\n\nContinue?"
			case $? in
			1) continue ;;
			3) break ;;
			esac

			if say "${MNT_LST[@]}" | grep -wq "$mntpt"; then
				ynwarn "The mountpoint $mntpt is already in use.\n\nContinue?"
				case $? in
				1) continue ;;
				3) break ;;
				esac
				MNT_LST=("${MNT_LST[@]/$(say "${MNT_LST[@]}" | grep -w "$mntpt")/}")
			fi
			MNT_LST+=("$devdisk $mntpt")
			if [ "$(say "${MNT_LST[@]}" | grep -w "/" | awk '{print "$2"}')" ]; then
				PRT_STAT="*"
			else
				PRT_STAT=""
			fi
			return
		done ;;
		"Format") while true; do
			xtrafs=""
			[ "$(say "${MNT_LST[@]}" | grep "/boot" | awk '{print "$2"}')" ] && xtrafs="\"Encrypted\" \"Encrypted filesystem, secure your data (/boot or /boot/efi is required)\""
			fsformat=$(dbox --cancel-label "Back" --menu "Please select the filesystem to be formated on $devdisk" 0 0 0 \
				"Ext2" "Standard Extended Filesystem for Linux version 2" \
				"Ext3" "Ext2 with journaling" \
				"Ext4" "Latest version of Extended Filesystem improved" \
				"BTRFS" "Filesystem for storing and managing large volume of data provided by BtrFS" \
				"XFS" "High-performance filesystem for server use" \
				"JFS" "Journaled filesystem by IBM" \
				"ZFS" "Filesystem for storing and managing large volume of data provided by OpenZFS" \
				"FAT32" "Compatible, highly usable filesystem for storing data only (ExtOS Frugal installable)" \
				"NTFS" "Standard Windows filesystem, use for data transfer only (ExtOS Frugal installable)" \
				"F2FS" "Fast filesystem for storing data only (ExtOS Frugal installable)" \
				"LVM" "Logical Volume Manager, useful if you want to have more partitions on disk that has 'msdos' partition table or when you have multiple disks (w or w/o RAID)" \
				$xtrafs \
				"Swap" "Virtual memory partition" \
				"Unformated" "Empty/Wiped partition") || break

			ynwarn "All data on ${devtype^} $devdisk will be erased\n\nContinue?"
			case $? in
			1) continue ;;
			3) break ;;
			esac

			if [[ "$devfstype" =~ "LVM".* ]]; then
				vgroup=$(pvs --noheadings -o vg_name "$devdisk" | awk '{print "$1"}')
				pvmove "$devdisk" &&
					vgchange -an "$vgroup" &&
					vgreduce "$vgroup" "$devdisk" &&
					pvremove "$devdisk" &&
					vgchange -ay "$vgroup" || break
			fi
			case "$fsformat" in
			Ext2 | Ext3 | Ext4) mkfs."${fsformat,,}" -F "$devdisk" ;;
			XFS) mkfs.xfs -f "$devdisk" ;;
			BTRFS | JFS | NTFS | F2FS) m kfs."${fsformat,,}" "$devdisk" ;;
			ZFS)
				zfs_id=$(randstr)
				zpool create -f "$zfs_id" "$devdisk"
				;;
			FAT32) mkfs.vfat -F 32 "$devdisk" ;;
			LVM) pvcreate "$devdisk" ;;
			Encrypted) while true; do
				ecryptpass=$(dbox --cancel-label "Back" --inputbox "Please enter the password for the encrypted filesystem" 0 0) || break
				if [ ! "$ecryptpass" ]; then
					errbox "Password cannot be empty"
					continue
				fi
				ecryptpass2=$(dbox --cancel-label "Back" --inputbox "Please re-enter the password to confirm" 0 0) || break

				if [ ! "$ecryptpass2" ]; then
					errbox "Password cannot be empty"
					continue
				fi
				if [ "$ecryptpass" != "$ecryptpass2" ]; then
					errbox "Password does not match, please try again"
					continue
				fi
				saybr "$ecryptpass\n$ecryptpass" | cryptsetup luksFormat "$devdisk"
				saybr "$ecryptpass" | cryptsetup open "$devdisk" "$(randstr)"
			done ;;
			Swap) mkswap "$devdisk" ;;
			Unformated) wipefs -a "$devdisk" ;;
			esac || errbox "Error while formating the partition $devdisk as $fsformat, please try again"
			return
		done ;;
		"Decrypt") while true; do
			cryptpass=$(dbox --inputbox "$devdisk appears to be an encrypted partition\nIt must be unlocked in order to continue\n\nPlease enter the encryption passphrase:" 0 0) || break

			[ "$cryptpass" ] || errbox "You didn't entered the encryption passphrase!"
			say "$cryptpass" | cryptsetup open "$devdisk" "$(randstr)" && return
			errbox "Could not unlock the partition.\n\nPlease check the passphrase and try again."
		done ;;
		"Manage") cfdisk "$devdisk" ;;
		"Manage LVM") advcd_lvm && return ;;
		*) break ;;
		esac
	done
}

advcd_diskman() {
	mount_check

	while true; do
		disklst
		if [ ! "${devs[*]}" ]; then
			dbox --msgbox "No device is available to install" 0 0
			return 1
		fi
		devdisk=$(dbox --cancel-label "Back" --ok-label "Select" --extra-button --extra-label "Next" --menu "Select the disk/partition for ExtOS to be installed on. Note that the disk/partition you select will be erased, but not until you have confirmed the changes.\n\nSelect the disk in the list below:" 0 80 0 "${devs[@]}")
		case $? in
		0)
			devtype=$(lsblk -d -n -r -o TYPE "$devdisk")
			devfstype=$(lsblk -d -n -r -o FSTYPE "$devdisk")
			if [ "$devtype" == "disk" ]; then
				dorpa="Partition table: $(fdisk -l "$devdisk" | grep Disklabel | awk '{print "$3"}')"
				dorpb="entire disk"
			else
				dorpa="Filesystem: $(lsblk -d -n -r -o FSTYPE "$devdisk")"
				dorpb="this partition"
			fi
			advcd_partopts
			continue
			;;
		3) diskconfirm=1 ;;
		esac
		break
	done
}
