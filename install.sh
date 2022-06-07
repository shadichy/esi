#!/bin/bash

label="EXTOS"

net=0
nct=0
lm=0
diskconfirm=0

bt="ExtOS-respin Installer"
tt="Installing progress"

netdone=""
keydone=""
locdone=""
tzcdone=""
usrdone=""
pttdone=""
osdone=""

mntlst=("")

sfsserverurl="https://example.com"

init() {
    case $(lscpu | grep Arch | awk '{print $2}') in
        "x86_64") lm=1;;
        "x86") lm=0;;
        *) dialog --backtitle "$bt" --title "$tt" --msgbox "Your CPU is not supported, please install on another computer"
        exit 1 ;;
    esac
    if [ -d /sys/firmware/efi ]; then
        cmos="uefi" 
    else
        cmos="bios"
    fi
    if curl -I http://archlinux.org || wget -q --spider http://archlinux.org || nc -zw1 archlinux.org 80; then
        net=2
        nct=0
        netdone="*"
    else
        if [ $nct -eq 1 ]; then
            if dialog --backtitle "$bt" --title "$tt" --yesno "Continue without network?" 0 0 ; then
                net=1
            fi
        fi
        netmes="\e[1;31mYou'll need to configure the network before installing or else some packages will be broken"
        netcheck
    fi
}

dircheck() {
    if [ $net -eq  2 ]; then
        workdir=$(find / -type d -iname "esi" 2>/dev/null | head -1)
        if [ ! -z $workdir ]; then
            cd $workdir
        else
            git clone https://github.com/shadichy/esi.git
            cd ./esi
            workdir=$(pwd)
        fi
    fi
}

netcheck() {
    if [ $net -eq 0 ]; then
        clear
        printf "$netmes\n"
        printf "\n"
        printf "\n"
        printf "\e[1;32mQuick guide:\n"
        printf "\n"
        printf "\e[1;33m  (For more 'space': Press Ctrl + Alt + F2 switching to TTY2 (Ctrl + Alt + F1 to get back) or open a new terminal window/tab/session(tmux))\n"
        printf "\n\e[1;36m"
        printf "    Run command 'ip link' to check enabled network interfaces\n"
        printf "    Run command 'rfkill list all' to list blocked network card and 'rfkill unblock all' to unblock all Soft-blocked network card\n"
        printf "    Run command 'iwctl' or 'wpa_cli' to configure wireless connection\n"
        printf "    Run command 'mmcli' to configure mobile network\n"
        printf "\n"
        printf "\e[1;35m  Finally, 'ping' some websites to check if it works or not\n"
        printf "\n"
        printf "\n"
        printf "\e[0mType 'exit' after you have done all the jobs\n"
        printf "\n"
        $SHELL
        nct=1
        init
    fi
}

keymapc() {
    while true; do
        KEYMAP=$(dialog --backtitle "$bt" --title "Set the Keyboard Layout" --nocancel --default-item "us" --menu "Select a keymap that corresponds to your keyboard layout. Choose 'other' if your keymap is not listed. If you are unsure, the default is 'us' (United States/QWERTY).\n\nKeymap:" 0 0 0 \
            "br-abnt2" "Brazilian Portuguese" \
            "cf" "Canadian-French" \
            "colemak" "Colemak (US)" \
            "dvorak" "Dvorak (US)" \
            "fr-latin1" "French" \
            "de-latin1" "German" \
            "gr" "Greek" \
            "it" "Italian" \
            "hu" "Hungarian" \
            "jp" "Japanese" \
            "pl" "Polish" \
            "pt-latin9" "Portuguese" \
            "ru4" "Russian" \
            "es" "Spanish" \
            "la-latin1" "Spanish Latinoamerican" \
            "sv-latin1" "Swedish" \
            "us" "United States" \
            "uk" "United Kingdom" \
            "other" "View all available keymaps" 3>&1 1>&2 2>&3)
        if [ "$KEYMAP" = "other" ]; then
            keymaps=()
            for map in $(localectl list-keymaps); do
                keymaps+=("$map" "")
            done
            KEYMAP=$(dialog --backtitle "$bt" --title "Set the Keyboard Layout" --cancel-label "Back" --menu "Select a keymap that corresponds to your keyboard layout. The default is 'us' (United States/QWERTY)." 0 0 0 "${keymaps[@]}" 3>&1 1>&2 2>&3)
            if [ $? -eq 0 ]; then
                break
            fi
        else
            break
        fi
    done
    localectl set-keymap "$KEYMAP"
    loadkeys "$KEYMAP"
    keydone="*"
}

localec() {
    while true; do
        LOCALE=$(dialog --backtitle "$bt" --title "Set the System Locale" --nocancel --default-item "en_US.UTF-8" --menu "Select a locale that corresponds to your language and region. The locale you select will define the language used by the system and other region specific information. Choose 'other' if your language and/or region is not listed. If you are unsure, the default is 'en_US.UTF-8'.\n\nLocale:" 0 0 0 \
            "en_AU.UTF-8" "English (Australia)" \
            "en_CA.UTF-8" "English (Canada)" \
            "en_US.UTF-8" "English (United States)" \
            "en_GB.UTF-8" "English (Great Britain)" \
            "fr_FR.UTF-8" "French (France)" \
            "de_DE.UTF-8" "German (Germany)" \
            "it_IT.UTF-8" "Italian (Italy)" \
            "ja_JP.UTF-8" "Japanese (Japan)" \
            "pt_BR.UTF-8" "Portuguese (Brazil)" \
            "pt_PT.UTF-8" "Portuguese (Portugal)" \
            "ru_RU.UTF-8" "Russian (Russia)" \
            "es_MX.UTF-8" "Spanish (Mexico)" \
            "es_ES.UTF-8" "Spanish (Spain)" \
            "sv_SE.UTF-8" "Swedish (Sweden)" \
            "vi_VN.UTF-8" "Vietnamese (Vietnam)" \
            "zh_CN.UTF-8" "Chinese (Simplified)" \
            "other" "View all available locales" 3>&1 1>&2 2>&3)
        if [ "$LOCALE" = "other" ]; then
            locales=()
            while read -r line; do
                locales+=("$line" "")
            done < <(grep -E "^#?[a-z].*UTF-8" /etc/locale.gen | sed -e 's/#//' -e 's/\s.*$//')
            LOCALE=$(dialog --backtitle "$bt" --title "Set the System Locale" --cancel-label "Back" --menu "Select a locale that corresponds to your language and region. The locale you select will define the language used by the system and other region specific information. If you are unsure, the default is 'en_US.UTF-8'.\n\nLocale:" 0 0 0 "${locales[@]}" 3>&1 1>&2 2>&3)
            if [ $? -eq 0 ]; then
                break
            fi
        else
            break
        fi
    done
    locdone="*"
}

localtz() {
    utc_enabled=true
    regions=()
    for region in $(find /usr/share/zoneinfo -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | grep -E -v '/$|posix|right' | sort); do
        regions+=("$region" "")
    done
    regions+=("other" "")

    while true; do
        ZONE=$(dialog --backtitle "$bt" --title "Set the Time Zone" --nocancel --menu "Select your time zone.\nIf your region is not listed, select 'other'.\n\nTime zone:" 0 0 0 "${regions[@]}" 3>&1 1>&2 2>&3)
        if [ "$ZONE" != "other" ]; then
            zone_regions=()
            for zone_region in $(find /usr/share/zoneinfo/"${ZONE}" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort); do
                zone_regions+=("$zone_region" "")
            done
            SUBZONE=$(dialog --backtitle "$bt" --title "Set the Time Zone" --cancel-label "Back" --menu "Select your time zone.\n\nTime zone:" 0 0 0 "${zone_regions[@]}" 3>&1 1>&2 2>&3)
            if [ $? -eq 0 ]; then
                if [ -d /usr/share/zoneinfo/"${ZONE}/${SUBZONE}" ]; then
                    subzone_regions=()
                    for subzone_region in $(find /usr/share/zoneinfo/"${ZONE}/${SUBZONE}" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort); do
                        subzone_regions+=("$subzone_region" "")
                    done
                    SUBZONE_SUBREGION=$(dialog --backtitle "$bt" --title "Set the Time Zone" --cancel-label "Back" --menu "Select your time zone.\n\nTime zone:" 0 0 0 "${subzone_regions[@]}" 3>&1 1>&2 2>&3)
                    if [ $? -eq 0 ]; then
                        ZONE="${ZONE}/${SUBZONE}/${SUBZONE_SUBREGION}"
                        break
                    fi
                else
                    ZONE="${ZONE}/${SUBZONE}"
                    break
                fi
            fi
        else
            for other_region in $(find /usr/share/zoneinfo -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | grep -E -v '/$|iso3166.tab|leapseconds|posixrules|tzdata.zi|zone.tab|zone1970.tab' | sort); do
                other_regions+=("$other_region" "")
            done
            ZONE=$(dialog --backtitle "$bt" --title "Set the Time Zone" --cancel-label "Back" --menu "Select your time zone.\n\nTime zone:" 0 0 0 "${other_regions[@]}" 3>&1 1>&2 2>&3)
            if [ $? -eq 0 ]; then
                ZONE="${ZONE}"
                break
            fi
        fi
    done
    dialog --backtitle "$bt" --title "Set the Hardware Clock" --nocancel --yesno "Would you like to set the hardware clock from the system clock using UTC time?\nIf you select no, local time will be used instead.\n\nIf you are unsure, UTC time is the default." 0 0
    if [ $? -ne 0 ]; then
        utc_enabled=false
    fi
    tzcdone="*"
}

usrname() {
    usrtt="User Configurations"
    while true; do
        FULL_NAME=$(dialog --backtitle "$bt" --title "$usrtt" --nocancel --inputbox "The installer will create a user account for you. This is the main user account that you will login to and use for non-administrative activities.\n\nPlease enter the real name for this user. This information will be used for any program that uses the user's real name such as email. Entering your full name here is recommended; however, it may be left blank.\n\nFull name for the new user:" 0 0 3>&1 1>&2 2>&3)
        while true; do
            USER_NAME=$(dialog --backtitle "$bt" --title "$usrtt" --cancel-label "Back" --inputbox "Please enter a username for the new account.\n\nThe username should start with a lower-case letter, which can be followed by any combination of numbers, more lower-case letters, or the dash symbol, and must not be match with any reserved system usernames (See: https://salsa.debian.org/installer-team/user-setup/raw/master/reserved-usernames).\n\nUsername for your account:" 0 0 "user" 3>&1 1>&2 2>&3)
            if [ $? -eq 0 ]; then
                if printf "%s" "$USER_NAME" | grep -Eoq "^[a-z][a-z0-9-]*$" && [ "${#USER_NAME}" -lt 33 ]; then
                    if grep -Fxq "$USER_NAME" "./reserved_usernames"; then
                        dialog --backtitle "$bt" --title "$usrtt" --msgbox "ERROR: The username you entered ($USER_NAME) is reserved for use by the system. Please select a different one." 0 0
                    else 
                        usrpswd_match=false
                        while ! $usrpswd_match; do
                            input=$(dialog --backtitle "$bt" --title "$usrtt" --clear --stdout --nocancel --insecure --passwordbox "Note: the default password of '$USER_NAME' is '123456'\n\nCreate a new password for '$USER_NAME':" 0 0 "123456")
                            if [ $input == 123456 ]; then
                                confirm_input=123456
                            else
                                confirm_input=$(dialog --backtitle "$bt" --title "$usrtt" --clear --stdout --insecure --passwordbox "Re-enter password to verify:" 0 0)
                            fi
                            if [ -z "$input" ]; then
                                dialog --backtitle "$bt" --title "$usrtt" --msgbox "ERROR: You are not allowed to have an empty password." 0 0
                            elif [ "$input" != "$confirm_input" ]; then
                                dialog --backtitle "$bt" --title "$usrtt" --msgbox "ERROR: The two passwords you entered did not match." 0 0
                            else
                                user_passwd="$input"
                                usrpswd_match=true
                            fi
                        done
                        break
                    fi
                else
                    dialog --backtitle "$bt" --title "$usrtt" --msgbox "ERROR: You entered an invalid username.\n\nThe username must start with a lower-case letter, which can be followed by any combination of numbers, more lower-case letters, or the dash symbol, must be no more than 32 characters long, and must not be match with any reserved system usernames (See: https://salsa.debian.org/installer-team/user-setup/raw/master/reserved-usernames)." 0 0
                fi
            fi
        done
        supswd_match=false
        while ! $supswd_match; do
            input=$(dialog --backtitle "$bt" --title "$usrtt" --clear --stdout --nocancel --insecure --passwordbox "Please set a password for 'root' (root is the Super User, the Administaion of the system, who grants permissions for you to do system jobs).\nThe default is 'root'\n\nRoot password:" 0 0 "root")
            if [ $input == root ]; then
                confirm_input=root
            else
                confirm_input=$(dialog --backtitle "$bt" --title "$usrtt" --clear --stdout --insecure --passwordbox "Re-enter password to verify:" 0 0)
            fi
            if [ -z "$input" ]; then
                dialog --backtitle "$bt" --title "$usrtt" --msgbox "ERROR: You are not allowed to have an empty password." 0 0
            elif [ "$input" != "$confirm_input" ]; then
                dialog --backtitle "$bt" --title "$usrtt" --msgbox "ERROR: The two passwords you entered did not match." 0 0
            else
                root_passwd="$input"
                supswd_match=true
            fi
        done
        HOST_NAME=$(dialog --backtitle "$bt" --title "$usrtt" --nocancel --inputbox "Please enter the hostname for this system.\n\nThe hostname is a single word that identifies your system to the network.\n\nHostname:" 0 0 "ExtOS" 3>&1 1>&2 2>&3)
        if printf "%s" "$HOST_NAME" | grep -Eoq "^[a-zA-Z0-9-]{1,63}$" && [ "${HOST_NAME:0:1}" != "-" ] && [ "${HOST_NAME: -1}" != "-" ]; then
            usrdone="*"
            break
        else
            dialog --backtitle "$bt" --title "$usrtt" --msgbox "ERROR: You entered an invalid hostname.\n\nA valid hostname may contain only the numbers 0-9, upper and lowercase letters (A-Z and a-z), and the minus sign. It must be at most 63 characters long, and may not begin or end with a minus sign." 0 0
        fi
    done
}

mntck() {
    for dir in $(ls -A /mnt); do
        if mountpoint -q $dir; then
            umount -R $dir
        fi
    done
    if mountpoint -q /mnt; then
        umount -R /mnt
    fi
    if free | awk '/^Swap:/ {exit !$2}'; then
        swapoff -a
    fi
    for vg in $(vgs --noheadings -o vg_name); do
        vgchange -ay $vg
    done
}

diskchoose() {
    diskconfirm=0
    while true; do
        disk=$(dialog --backtitle "$bt" --title "Partition the harddrive" --stdout --cancel-label "Exit to Menu" --menu "Disk/partition options" 0 0 0 \
            "Auto" "Automatically choosing disk and partition to install (alongside other operating systems)" \
            "Basic" "Select (a) disk/partition(s) to install" \
            "Manual" "Customize disk/partition layout")
        case "$disk" in
            "Auto")
                for d in $(lsblk -n -p -r -e 7,11,251 -d -o NAME); do
                    ptb=$(printf "fix\n" | parted ---pretend-input-tty $d print | grep "Partition Table" | awk '{print $3}')
                    case $ptb in
                        "gpt")
                            part_type=$label
                            ;;
                        "msdos")
                            part_type="primary"
                            ;;
                        *) continue ;;
                    esac
                    create_part() {
                        while IFS= read -r f; do
                            part_size=$(echo $f | awk '{print $3}')
                            if (( $(echo "${part_size%MiB} >= 4096" |bc -l) )); then
                                part_start=$(printf $f | awk '{print $1}')
                                part_end=$(printf $f | awk '{print $2}')
                                part_table_before=( "$(lsblk -n -p -r -e 7,11,251 -o NAME $d)" )
                                printf "fix\n" | parted ---pretend-input-tty $d mkpart $part_type ext4 $part_start $part_size
                                if [ $? -ne 0 ]; then
                                    continue
                                fi
                                part_table_after=( "$(lsblk -n -p -r -e 7,11,251 -o NAME $d)" )
                                part_id=$(echo ${part_table_before[@]} ${part_table_after[@]} | tr ' ' '\n' | sort | uniq -u)
                                if [ $ptb = "msdos" ]; then
                                    printf "fix\n" | parted ---pretend-input-tty $part_id -name $label
                                    if [ $? -ne 0 ]; then
                                        continue
                                    fi
                                fi
                                e2label $part_id $label
                                e2fsck -f $part_id
                                mntlst=( "$part_id /" )
                                diskconfirm=1
                            fi
                        done <<< "$(printf "fix\n" | parted ---pretend-input-tty $d unit MiB print free | grep "Free Space")"
                    }
                    create_part
                    if [ ! -z $(printf '%s\n' "${mntlst[@]}" | grep -w "/" | awk '{print $2}') ]; then
                        break
                    fi
                    for p in $(lsblk -n -p -r -e 7,11,251 -o NAME $d | grep -vw $d); do
                        part_fs=$(lsblk -d -n -r -o FSTYPE $p)
                        if [[ $part_fs =~ "crypt".* ]] || [[ $part_fs =~ "swap".* ]] || [[ $part_fs =~ "LVM".* ]] || [[ $part_fs =~ "raid".* ]] || [[ -z $part_fs ]]; then
                            continue
                        fi
                        if ! mount $p /mnt; then
                            continue
                        fi
                        if [ $(df -m --output=avail /mnt | grep -v "Avail") -lt 4096 ]; then
                            umount /mnt
                            continue
                        fi
                        umount /mnt
                        printf "fix\n" | parted ---pretend-input-tty $p resizepart 1 $(( ${(printf "fix\n" | parted ---pretend-input-tty $p unit MiB print | grep -w "1" | awk '{print $3}')%MiB} - 4096 ))
                        if [ $? -ne 0 ]; then
                            continue
                        fi
                        create_part
                        if [ diskconfirm -eq 1 ]; then
                            break
                        fi
                    done
                    if [ diskconfirm -eq 1 ]; then
                        break
                    fi
                done
                if [ diskconfirm -eq 1 ]; then
                    break
                fi
                ;;
            "Basic") simplediskman
                if [ $diskconfirm -eq 1 ]; then
                    break
                fi ;;
            "Manual")
                dialog --backtitle "$bt" --title "Manual partitioning" --yes-label "Use Terminal interface" --no-label "Use Command line interface" --yesno "Would you like to use the terminal interface or the command line interface?" 0 0
                if [ $? -eq 0];then
                    diskman
                    if [ $diskconfirm -eq 1 ]; then
                        break
                    fi
                fi
                clear
                printf "\n"
                printf "\n"
                printf "\e[1;32mQuick guide:\n"
                printf "\n"
                printf "\e[1;33m### Physical Disk/Partition Management ###\e[0m\n"
                printf "\n\e[1;36m"
                printf "    Use 'lsblk' to see the list of disks/partitions.\n\n"
                printf "    Use 'fdisk', 'cfdisk', 'parted' commands or any CLI-based disk utilities to manage disks/partitions\n"
                printf "\n"
                printf "\e[1;33m### Logical Volume Management ###\e[0m\n"
                printf "\n\e[1;36m"
                printf "    Use pvdisplay, pvcreate, pvremove commands to manage physical volumes\n"
                printf "    Use vgdisplay, vgcreate, vgremove commands to manage volume groups\n"
                printf "    Use lvdisplay, lvcreate, lvremove commands to manage logical volumes\n"
                printf "\n"
                printf "\e[1;33m### Encrypted Volume Management ###\e[0m\n"
                printf "\n\e[1;36m"
                printf "    Use cryptsetup commands to manage encrypted volumes\n"
                printf "\n"
                printf "\e[0mType 'exit' after you have done all the jobs\n"
                printf "\n"
                $SHELL
                diskman
                if [ $diskconfirm -eq 1 ]; then
                    break
                fi ;;
            *) menusel ;;
        esac
    done
}

disklst() {
    unset devs
    for dev in $(lsblk -n -p -r -e 7,11,251 -o NAME); do
        if [ ! -z $(printf '%s\n' "${devs[@]}" | grep -w "$dev") ]; then
            continue
        fi
        devsz=$(lsblk -d -n -r -o SIZE "$dev")
        devtp=$(lsblk -d -n -o TYPE $dev)
        devfs=$(lsblk -d -n -r -o FSTYPE "$dev")
        devmp=" "
        hasmntpt=$(printf "%s\n" "${mntlst[@]}" | grep -w "$dev")
        if [ ! -z "$hasmntpt" ]; then
            devmp=$(echo $hasmntpt | awk '{print $2}')
        fi
        devs+=("$dev"$'\t'"" "$devtp"$'\t'"$devfs"$'\t'"$devsz"$'\t'"$devmp")
    done
}
simplediskman() {
    disklst
    mntck
    while true; do
        if [ ${#devs[@]} -eq 0 ]; then
            dialog --backtitle "$bt" --title "Partition the harddrive" --msgbox "No device is available to install" 0 0
            break
        fi
        devdisk=$(dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --ok-label "Select" --stdout --menu "Select the disk/partition for ExtOS to be installed on. Note that the disk/partition you select will be erased, but not until you have confirmed the changes.\n\nSelect the disk in the list below:" 0 80 0 "${devs[@]}")
        if [ $? -ne 0 ]; then
            break
        fi
        devtype=$(lsblk -d -n -r -o TYPE $devdisk)
        if [ $devtype == "disk" ]; then
            dorpb="entire disk"
        else
            dorpb="partition"
        fi
        dialog --backtitle "$bt" --title "Confirm install on $devdisk" --yes-label "Confirm" --no-label "Back" --yesno "Are you sure you want to install ExtOS on the $dorpb $devdisk?\n\nThis will erase all data on the $devdisk, and cannot be undone." 0 0
        if [ $? -ne 0 ]; then
            continue
        fi
        case $devtype in
            "part")
                dialog --backtitle "$bt" --title "Formatting $devdisk" --infobox "Formatting $devdisk as ext4" 0 0
                mkfs.ext4 -F -L EXTOS $devdisk
                if [ $? -ne 0 ]; then
                    dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to format $devdisk" 0 0
                    continue
                fi
                mntlst+=("$devdisk /")
                flagasboot() {
                    parted -s $devdisk set 1 boot on
                    if [ $? -ne 0 ]; then
                        dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to set $devdisk as bootable" 0 0
                        continue
                    fi
                }
                case $cmos in
                    "uefi")
                        espdev=$(lsblk -o NAME,LABEL,PARTLABEL | grep -w "EFI" | awk '{print $1}')
                        if [ -z "$espdev" ]; then
                            flagasboot
                        else
                            mntlst+=("$espdev /boot/efi")
                        fi ;;
                    "bios") flagasboot ;;
                esac
                ;;
            "disk")
                case $cmos in
                    "uefi")
                        dialog --backtitle "$bt" --title "Formatting $devdisk" --infobox "Creating GPT partition table on $devdisk" 0 0
                        parted -s $devdisk mklabel gpt
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to create GPT partition table on $devdisk" 0 0
                            continue
                        fi
                        dialog --backtitle "$bt" --title "Formatting $devdisk" --infobox "Creating EFI system partition" 0 0
                        parted -s $devdisk mkpart EFI_EXTOS fat32 1 100M
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to create EFI system partition on $devdisk" 0 0
                            continue
                        fi
                        dialog --backtitle "$bt" --title "Formatting $devdisk" --infobox "Formatting EFI system partition as fat32" 0 0
                        mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI_EXTOS
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to format EFI system partition as fat32" 0 0
                            continue
                        fi
                        parted -s /dev/disk/by-partlabel/EFI_EXTOS set 1 boot on
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to set EFI system partition as bootable" 0 0
                            continue
                        fi
                        parted -s /dev/disk/by-partlabel/EFI_EXTOS set 1 esp on
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to set EFI system partition as ESP" 0 0
                            continue
                        fi
                        mntlst+=("/dev/disk/by-partlabel/EFI_EXTOS /boot/efi")
                        dialog --backtitle "$bt" --title "Formatting $devdisk" --infobox "Creating partition to install ExtOS" 0 0
                        parted -s $devdisk mkpart EXTOS ext4 101M 100%
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to create partition on $devdisk" 0 0
                            continue
                        fi
                        dialog --backtitle "$bt" --title "Formatting $devdisk" --infobox "Formatting $devdisk as ext4" 0 0
                        mkfs.ext4 -F -L EXTOS /dev/disk/by-partlabel/EXTOS
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to format $devdisk" 0 0
                            continue
                        fi
                        mntlst+=("/dev/disk/by-partlabel/EXTOS /")
                        ;;
                    "bios")
                        dialog --backtitle "$bt" --title "Formatting $devdisk" --infobox "Formatting $devdisk as msdos" 0 0
                        parted -s $devdisk mklabel msdos
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to format $devdisk" 0 0
                            continue
                        fi
                        dialog --backtitle "$bt" --title "Formatting $devdisk" --infobox "Creating partition for rootfs" 0 0
                        parted -s $devdisk mkpart primary ext4 100%
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to create partition on $devdisk" 0 0
                            continue
                        fi
                        pdev=$(lsblk -n -r -p -o NAME $devdisk | grep -vw "$devdisk")
                        dialog --backtitle "$bt" --title "Formatting $devdisk" --infobox "Formatting $pdev as ext4" 0 0
                        mkfs.ext4 -F -L EXTOS $pdev
                        if [ $? -ne 0 ]; then
                            dialog --backtitle "$bt" --title "Formatting $devdisk" --msgbox "Failed to format $pdev" 0 0
                            continue
                        fi
                        mntlst+=("$pdev /")
                        ;;
                esac
                ;;
        esac
        diskconfirm=1
        pttdone="*"
        break
    done
}

diskman() {
    disklst
    mntck
    while true; do
        if [ ${#devs[@]} -eq 0 ]; then
            dialog --backtitle "$bt" --title "Partition the harddrive" --msgbox "No device is available to install" 0 0
            break
        fi
        devdisk=$(dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --ok-label "Select" --extra-button --extra-label "Next" --stdout --menu "Select the disk/partition for ExtOS to be installed on. Note that the disk/partition you select will be erased, but not until you have confirmed the changes.\n\nSelect the disk in the list below:" 0 80 0 "${devs[@]}")
        case $? in
            0)
                devtype=$(lsblk -d -n -r -o TYPE $devdisk)
                devfstype=$(lsblk -d -n -r -o FSTYPE $devdisk)
                if [ $devtype == "disk" ]; then
                    dorpa="Partition table: $(fdisk -l $devdisk | grep Disklabel | awk '{print $3}')"
                    dorpb=" entire disk"
                else
                    dorpa="Filesystem: $(lsblk -d -n -r -o FSTYPE $devdisk)"
                    dorpb=""
                fi
                while true; do
                    cryptopt=""
                    if [[ $devfstype =~ "crypt".* ]]; then
                        cryptopt="\"Decrypt\" \"Mount Encrypted\""
                    fi
                    if [ $devtype == "disk" ]; then
                        cryptopt="\"Manage\" \"Manage Volumes/Partitions\""
                    fi
                    mntopts=$(dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --stdout --menu "${devtype^^} $devdisk\n    Type: $devtype\n    $dorpa\n    Size: $(lsblk -d -n -r -o SIZE $devdisk)\n    In use: none\n\nChoose an action:" 0 0 0 \
                    "Mountpoint" "Use$dorpb as " \
                    "Format" "Format/Erase/Change filesystem of$dorpb" \
                    $cryptopt \
                    $lvmopt)
                    if [ $? -ne 0 ]; then
                        break
                    fi
                    case $mntopts in
                        "Mountpoint") while true; do
                            mntpt=$(dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --stdout --menu "Choose mountpoint for $devtype $devdisk:\n\nNote: everything except "/" and "/boot" are optional" 0 0 0 \
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
                            "swap" "Virtual memory partition" )
                            if [ $? -ne 0 ]; then
                                break
                            fi
                            if dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --yesno "Warning: All data on ${devtype^} $devdisk will be erased\n\nContinue?" 0 0 ; then
                                if [ ! -z "$(printf "%s\n" "${mntlst[@]}" | grep -w "$mntpt")" ]; then
                                    if dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --yesno "Warning: The mountpoint $mntpt is already in use.\n\nContinue?" 0 0 ; then
                                        mntlst=( "${mntlst[@]/$(printf "%s\n" "${mntlst[@]}" | grep -w "$mntpt")}" )
                                    else
                                        break
                                    fi
                                fi
                                mntlst+=("$devdisk $mntpt")
                                if [ ! -z $(printf '%s\n' "${mntlst[@]}" | grep -w "/" | awk '{print $2}') ]; then
                                    pttdone="*"
                                else
                                    pttdone=""
                                fi
                            fi
                            disklst
                            break
                        done ;;
                        "Format") while true;do
                            fsformat=$(dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --stdout --menu "Please select the filesystem to be formated on $devdisk" 0 0 0 \
                            "Ext2" "Standard Extended Filesystem for Linux version 2" \
                            "Ext3" "Ext2 with journaling" \
                            "Ext4" "Latest version of Extended Filesystem improved" \
                            "BTRFS" "Filesystem for storing and managing large volume of data provided by Btrfs" \
                            "XFS" "High-performance filesystem for server use" \
                            "JFS" "Journaled filesystem by IBM" \
                            "ZFS" "Filesystem for storing and managing large volume of data provided by OpenZFS" \
                            "FAT32" "Compatible, highly usable filesystem for storing data only (ExtOS Frugal installable)" \
                            "NTFS" "Standard Windows filesystem, use for data transfer only (ExtOS Frugal installable)" \
                            "F2FS" "Fast filesystem for storing data only (ExtOS Frugal installable)" \
                            "LVM" "Logical Volume Manager, useful if you want to have more partitions on the disk that has 'msdos' partition table or when you have multiple disks (with or without RAID)" \
                            "Encrypted" "Encrypted filesystem, secure your data" \
                            "Swap" "Virtual memory partition" \
                            "Unformated" "Unformated partition" )
                            if [ $? -ne 0 ]; then
                                break
                            fi
                            dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --yesno "Warning: All data on ${devtype^} $devdisk will be erased\n\nContinue?" 0 0
                            if [ $? -ne 0 ]; then
                                break
                            fi
                            if [[ $devfstype =~ "LVM".* ]]; then
                                vgroup=$(pvs --noheadings -o vg_name $devdisk | awk '{print $1}')
                                pvmove "$devdisk"
                                if [ $? -ne 0 ]; then
                                    break
                                fi
                                vgchange -an "$vgroup"
                                if [ $? -ne 0 ]; then
                                    break
                                fi
                                vgreduce "$vgroup" "$devdisk"
                                if [ $? -ne 0 ]; then
                                    break
                                fi
                                pvremove "$devdisk"
                                if [ $? -ne 0 ]; then
                                    break
                                fi
                                vgchange -ay "$vgroup"
                                if [ $? -ne 0 ]; then
                                    break
                                fi
                            fi
                            case $fsformat in 
                                "Ext2")
                                    mkfs.ext2 -F $devdisk
                                    ;;
                                "Ext3")
                                    mkfs.ext3 -F $devdisk
                                    ;;
                                "Ext4")
                                    mkfs.ext4 -F $devdisk
                                    ;;
                                "BTRFS")
                                    mkfs.btrfs $devdisk
                                    ;;
                                "XFS")
                                    mkfs.xfs -f $devdisk
                                    ;;
                                "JFS")
                                    mkfs.jfs $devdisk
                                    ;;
                                "ZFS")
                                    zpool create -f $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1) $devdisk
                                    ;;
                                "FAT32")
                                    mkfs.vfat -F 32 $devdisk
                                    ;;
                                "NTFS")
                                    mkfs.ntfs $devdisk
                                    ;;
                                "F2FS")
                                    mkfs.f2fs $devdisk
                                    ;;
                                "LVM")
                                    pvcreate $devdisk
                                    ;;
                                "Encrypted") while true;do
                                    # ask for password
                                    ecryptpass=$(dialog --backtitle "$bt" --title "Partition the harddrive" --stdout --cancel-label "Back" --inputbox "Please enter the password for the encrypted filesystem" 0 0)
                                    if [ $? -ne 0 ]; then
                                        break
                                    fi
                                    if [ -z $ecryptpass ]; then
                                        dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --msgbox "Password cannot be empty" 0 0
                                        continue
                                    fi
                                    ecryptpass2=$(dialog --backtitle "$bt" --title "Partition the harddrive" --stdout --cancel-label "Back" --inputbox "Please re-enter the password to confirm" 0 0)
                                    if [ $? -ne 0 ]; then
                                        break
                                    fi
                                    if [ -z $ecryptpass2 ]; then
                                        dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --msgbox "Password cannot be empty" 0 0
                                        continue
                                    fi
                                    if [ "$ecryptpass" != "$ecryptpass2" ]; then
                                        dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --msgbox "Password does not match, please try again" 0 0
                                    else
                                        echo -e "$ecryptpass\n$ecryptpass" | cryptsetup luksFormat $devdisk
                                        echo -e "$ecryptpass" | cryptsetup open $devdisk $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
                                    fi
                                done ;;
                                "Swap")
                                    mkswap $devdisk
                                    ;;
                                "Unformated")
                                    wipefs -a $devdisk
                                    ;;
                            esac
                            if [ $? -ne 0 ]; then
                                dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --msgbox "Error while formating the partition $devdisk as $fsformat, please try again" 0 0
                                break
                            fi
                        done ;;
                        "Decrypt") while true; do
                            cryptpass=$(dialog --backtitle "$bt" --title "Partition the harddrive" --stdout --inputbox "$devdisk appears to be an encrypted partition\nIt must be unlocked in order to continue\n\nPlease enter the encryption passphrase:" 0 0)
                            if [ $? -ne 0 ]; then
                                break
                            fi
                            if [ -z $cryptpass ]; then
                                dialog --backtitle "$bt" --title "Partition the harddrive" --msgbox "ERROR: You didn't entered the encryption passphrase!"
                            fi
                            if echo -e "$cryptpass" | cryptsetup open $devdisk $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1); then
                                break
                            else
                                dialog --backtitle "$bt" --title "Partition the harddrive" --msgbox "ERROR: Could not unlock the partition.\n\nPlease check the passphrase and try again."
                            fi
                        done ;;
                        "Manage") while true; do
                            cfdisk $devdisk
                        done ;;
                    esac
                    break
                done
                ;;
            3)
                diskconfirm=1
                break
                ;;
            *)
                break
                ;;
        esac
    done
}

ossel() {
    while true; do
        osbs=$(dialog --backtitle "$bt" --title "$tt" --stdout --cancel-label "Exit to menu" --menu "Choose based distro" 0 0 0 \
        "Arch" "Arch Linux based ExtOS full installation" \
        "Debian" "Debian based full installation" \
        "Frugal" "Minimal frugal installation")
        if [ $? -ne 0 ]; then
            menusel
            return
        fi
        if [ $lm -eq 1 ]; then
            if dialog --backtitle "$bt" --title "$tt" --yesno "Your CPU supports 64-bit architecture, would you like to install ExtOS 64bit?" 0 0; then
                arct="amd64"
            else
                arct="i386"
            fi
        else
            arct="i386" Uses i686 instead
        fi
        picustom="\"custom\" \"Customize your own preset\" off"
        case $osbs in
            "Arch") osbs="arch" ;;
            "Debian") osbs="deb" ;;
            "Frugal") osbs="sfs"; picustom="" ;;
        esac
        initsel
        if [ ! -z "$osdone" ]; then
            break
        fi
    done
    start_install
}

initsel(){
    while true; do
        initype=$(dialog --backtitle "$bt" --title "$tt" --stdout --cancel-label "Back" --radiolist "Use arrow keys and Space to select which init system you would prefered\n\nComparision: https://wiki.gentoo.org/wiki/Comparison_of_init_systems" 0 0 0 \
        "SystemD" "Standard init system, provides more than just an init system" on\
        "OpenRC" "SysVinit based, suitable for minimal installation" off\
        "runit" "A daemontools-inspired process supervision suite" off)
        if [ $? -ne 0 ]; then
            break
        fi
        case $initype in
            "SystemD")
                initype="sysd"
                ;;
            "OpenRC")
                initype="oprc"
                ;;
            "runit")
                initype="rnit"
                ;;
        esac
        libcsel
        if [ ! -z "$osdone" ]; then
            break
        fi
    done
}

libcsel() {
    while true; do
        libctype=$(dialog --backtitle "$bt" --title "$tt" --stdout --cancel-label "Back" --radiolist "Use arrow keys and Space to select which libc you would prefered\n\nComparision: https://wiki.gentoo.org/wiki/Comparison_of_libc" 0 0 0 \
        "glibc" "Standard libc, supports most of the modern linux kernel" on\
        "musl" "Minimal libc, supports only the bare minimum for the kernel" off)
        if [ $? -ne 0 ]; then
            break
        fi
        pisel
        if [ ! -z "$osdone" ]; then
            break
        fi
    done
}

pisel() {
    while true;do
        piscript=$(dialog --backtitle "$bt" --title "$tt" --stdout --ok-label "Next" --cancel-label "Back" --extra-button --extra-label "Skip" --checklist "Choose one of the presets below, or do it later\nUse arrows key and space" 0 0 0 \
        "encrypted" "Destination disk will be encrypted with LUKS" off \
        "gaming" "Cross-play suite for gamers" off \
        "office" "Suit for office work, with many useful softwares" off \
        "devel" "Developing enviroment for coders/developers" off \
        "server" "Tools and utilities for a mini host server" off \
        $picustom)
        case $? in
            0)
                for f in $piscript; do
                    if [ -f "preset/$f/$arct/pkglist-$osbs" ]; then
                        cat preset/$f/$arct/pkglist-$osbs >> pkglist
                    fi
                done
                sort -u pkglist -o pkglist
                if [ "$piscript" == "*custom*" ]; then
                    pkglist=$(dialog --backtitle "$bt" --title "Customize your own preset" --stdout --ok-label "Save" --cancel-label "Continue" --editbox "pkglist" 0 0)
                    if [ $? -eq 0 ]; then
                        echo $pkglist > pkglist
                    fi
                fi
                osdone="*"
                break
                ;;
            1)
                break
                ;;
            3)
                osdone="*"
                break
                ;;
        esac
        if [ ! -z "$osdone" ]; then
            break
        fi
    done
}

mount_part() {
    mount -m "$1" "/mnt$2"
}

start_install(){
    if ! dialog --backtitle "$bt" --title "Confirmation" --yesno "You have selected these:\n\n\
    Base: $osbs\n\
    Init system: $initype\n\
    Libc: $libctype\n\
    Presets: $piscript\n\

    Partition table: \n\
    $(printf "\t%s\n" "${mntlst[@]}")\n\
    \n\
    Do you want to continue?" 0 0; then
        ossel
        return
    fi

    if [ "$piscript" == "*encrypted*" ]; then
        for mnt in "$(printf '%s\n' "${mntlst[@]}" | grep -v "/boot" | awk '{print $1}')"; do
            while true; do
                psk=$(dialog --backtitle "$bt" --title "Encryption password" --stdout --passwordbox "Enter a password for $mnt" 0 0)
                if [ $? -ne 0 ]; then
                    start_install
                    return
                fi
                if [ -z "$psk" ]; then
                    dialog --backtitle "$bt" --title "Error" --msgbox "Password cannot be empty" 0 0
                    continue
                fi
                break
            done
            cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 -i 5000 -d "$psk" "$mnt"
            if [ $? -ne 0 ]; then
                dialog --backtitle "$bt" --title "Error" --msgbox "Error while encrypting $mnt" 0 0
                start_install
                return
            fi
            randomname=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
            echo $psk | cryptsetup open "$mnt" "$randomname"
            if [ $? -ne 0 ]; then
                dialog --backtitle "$bt" --title "Error" --msgbox "Error while opening $mnt" 0 0
                start_install
                return
            fi
            mkfs.ext4 -L "$randomname" "/dev/mapper/$randomname"
            if [ $? -ne 0 ]; then
                dialog --backtitle "$bt" --title "Error" --msgbox "Error while formatting $mnt" 0 0
                start_install
                return
            fi
        done
    fi

    mount_part $(printf '%s\n' "${mntlst[@]}" | grep -w "/")
    if [ $? -ne 0 ]; then
        dialog --backtitle "$bt" --title "$tt" --msgbox "ERROR: Failed to mount the root partition!"
        menusel
        return
    fi

    if ! curl -L -o /mnt/rootfs.sfs "$sfsserverurl/root-$osbs-$initype-$libctype-$arct.sfs" || ! wget -O /mnt/rootfs.sfs "$sfsserverurl/root-$osbs-$initype-$libctype-$arct.sfs"; then
        dialog --backtitle "$bt" --title "$tt" --msgbox "ERROR: Failed to download the rootfs image!"
        menusel
        return
    fi
    for pi in "${piscript[@]}"; do
        if [ $pi = "custom" ]; then
            continue
        fi
        if ! curl -L -o /mnt/pi/$pi.sfs "$sfsserverurl/pi/$pi.sfs" || ! wget -O /mnt/pi/$pi.sfs "$sfsserverurl/pi/$pi.sfs"; then
            dialog --backtitle "$bt" --title "$tt" --msgbox "ERROR: Failed to download the $pi image!"
            menusel
            return
        fi
    done
    if [ "$osbs" != "sfs" ]; then
        for i in $(printf '%s\n' "${mntlst[@]}" | grep -Evw "/|/data|/overlay|swap"); do
            mount_part $i
            if [ $? -ne 0 ]; then
                dialog --backtitle "$bt" --title "$tt" --msgbox "ERROR: Failed to mount the $i partition!"
                menusel
                return
            fi
        done
        if ! unsquashfs -f -d /mnt /mnt/rootfs.sfs; then
            dialog --backtitle "$bt" --title "$tt" --msgbox "ERROR: Failed to unpack the rootfs image!"
            menusel
            return
        fi
        if ! echo "${piscript[@]}" | grep -q "custom"; then
            for pi in "${piscript[@]}"; do
                if ! unsquashfs -f -d /mnt /mnt/pi/$pi.sfs; then
                    dialog --backtitle "$bt" --title "$tt" --msgbox "ERROR: Failed to unpack the $pi image!"
                    menusel
                    return
                fi
            done
        else
            for pi in "${piscript[@]}"; do
                if [ $pi = "custom" ]; then
                    continue
                fi
                cp -r preset/$pi/$arct/* /mnt
            done
            if [ "$osbs" == "deb" ]; then
                chroot /mnt apt-get update
                chroot /mnt xargs apt-get -y install < pkglist
            elif [ "$osbs" == "arch" ]; then
                chroot /mnt pacman -S - < pkglist
            fi
        fi
    else
        if ! curl -L -o /mnt/data.img "$sfsserverurl/data-$arct.img" || ! wget -O /mnt/data.img "$sfsserverurl/data-$arct.img"; then
            dialog --backtitle "$bt" --title "$tt" --msgbox "ERROR: Failed to download the data.img image!"
            menusel
            return
        fi
        external_data=$(printf '%s\n' "${mntlst[@]}" | grep -w "/data")
        if [ -n "$external_data" ]; then
            external_data_dev=$(echo $external_data | awk '{print $1}')
            dd if=/mnt/data.img of=$external_data_dev bs=4M
            sed -i "s/data=\/cdrom\/data.img/data=$external_data_dev/g" /mnt/boot/grub/grub.cfg
        fi
        cp -r preset/0-global/$arct/boot /mnt/boot
        if dialog --backtitle "$bt" --title "Overlay" --yesno "Do you want to enable overlay?"; then
            external_overlay=$(printf '%s\n' "${mntlst[@]}" | grep -w "/overlay")
            if [ -n "$external_overlay" ]; then
                overlay_dev=$(echo $external_overlay | awk '{print $1}')
            else
                overlay_dev=/mnt/overlay.img
                dd if=/dev/zero of=$overlay_dev bs=1M count=$(($(df -m /mnt | tail -n 1 | awk '{print $2}') - $(du -m /mnt/root.sfs | awk '{print $1}') - $(du -m /mnt/data.img | awk '{print $1}') - $(du -m /mnt/pi | awk '{print $1}')))
            fi
            mkfs.ext4 -L overlay $overlay_dev
            sed -i "s/overlay=tmpfs/overlay=$overlay_dev/" /mnt/boot/grub/grub.cfg
            sed -i "s/overlayfstype=tmpfs overlayflags=nodev,nosuid//" /mnt/boot/grub/grub.cfg
        else
            sed -i "s/overlay=tmpfs overlayfstype=tmpfs overlayflags=nodev,nosuid//" /mnt/boot/grub/grub.cfg
            dd if=/dev/zero of=/mnt/data.img bs=1M count=$(($(df -m /mnt | tail -n 1 | awk '{print $2}') - $(du -m /mnt/root.sfs | awk '{print $1}') - $(du -m /mnt/pi | awk '{print $1}')))
        fi
    fi
    is it finished?
    no u fcking idiot, there are lots of things to do here
    dialog --backtitle "$bt" --title "Finished" --extra-button --extra-label "Other" --yesno "Do you want to reboot?"
    case $? in
        0)
            reboot
            ;;
        1)
            menusel
            ;;
    esac
}

poweropts() {
    pwvar=$(dialog --backtitle "$bt" --title "Power options" --cancel-label "Back" --stdout --menu "Choose option to continue:" 0 0 0 \
        "Reboot   " "Restart the machine and also the installer" \
        "Sleep    " "Suspend the machine and save current state to RAM/swap" \
        "Hibernate" "Hibernate the machine and save current state to disk/RAMdisk" \
        "Shutdown " "Exit the installer and power off the  machine")
    case $pwvar in
        "Reboot   ") reboot ;;
        "Sleep    ") suspend;;
        "Hibernate") systemctl hibernate;;
        "Shutdown ") poweroff;;
    esac
}

menusel() {
    while true; do
    choice=$(dialog --backtitle "$bt" --title "Main Menu" --nocancel \
        --menu "Select an option below using the UP/DOWN, PLUS(+) or MINUS(-) keys and SPACE or ENTER.\nIf there is an asterisk at the end of the entry means it's configured" 0 0 0 \
            "NETWORK    " "Manually config the network           $netdone" \
            "KEYMAP     " "Set the keyboard layout               $keydone" \
            "LOCALE     " "Set the system locale                 $locdone" \
            "TIMEZONE   " "Set the system time zone              $tzcdone" \
            "CREATE USER" "Create your user account              $usrdone" \
            "PARTITION  " "Partition the installation drive      $pttdone" \
            "INSTALL    " "Install ExtOS Linux respin" \
            "POWER      " "Power options" \
            "EXIT       " "Exit the installer" \
            3>&1 1>&2 2>&3)
        case "$choice" in
            "NETWORK    ") netmes="\e[0mFrom here you'll configure the network manually"; netcheck ;;
            "KEYMAP     ") keymapc ;;
            "LOCALE     ") localec ;;
            "TIMEZONE   ") localtz ;;
            "CREATE USER") usrname ;;
            "PARTITION  ") diskchoose ;;
            "INSTALL    ") ossel ;;
            "POWER      ") poweropts ;;
            *) reset; printf "Run ./install.sh to restart the installer\n"; exit ;;
        esac
    done
}

main(){
    init
    dircheck
    keymapc
    localec
    localtz
    usrname
    diskchoose
    ossel
    poweropts
}

if [ "$EUID" -ne 0 ]; then
    dialog --backtitle "$bt" --title "ERROR" --msgbox "Please run this script as root."
    exit
fi
if dialog --backtitle "$bt" --title "$tt" --yesno "This is ExtOS linux respin v0.1\nMade by Shadichy\n\nStart installation process?" 0 0
then
    menusel
    # main "$@"
else
    printf "Run ./install.sh to restart the installer\n"
fi
