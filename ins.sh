#!/bin/bash
net=0
nct=0
workdir=$(pwd)
bt="ExtOS-respin Installer"
tt="Installing progres"
netdone=""
keydone=""
locdone=""
tzcdone=""
usrdone=""
pttdone=""
distrose="Choose based distribution by selecting then press Space\n\n         BASED ON        ARCH            VERSION         INIT"
netinit () {
    if nc -zw1 archlinux.org 80 || wget -q --spider http://archlinux.org; then
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
        if [ -d ~/esi ]; then
            cd ~/esi
        elif [ -d ./esi ]; then
            cd ./esi
        elif [ -d ../esi ]; then
            cd ../esi
        else
            git clone https://github.com/shadichy/esi.git
            cd ./esi
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
        printf "\e[1;33m  (For more 'spaces': Press Ctrl + Alt + F2 switching to TTY2 (Ctrl + Alt + F1 to get back))\n"
        printf "\n\e[1;36m"
        printf "    Run command 'ip link' to check enabled network interfaces\n"
        printf "    Run command 'rfkill list all' to list blocked network card and 'rfkill unlock all' to unlock all Soft-blocked network card\n"
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
        netinit
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
            USER_NAME=$(dialog --backtitle "$bt" --title "$usrtt" --cancel-label "Back" --inputbox "Please enter a username for the new account.\n\nThe username should start with a lower-case letter, which can be followed by any combination of numbers, more lower-case letters, or the dash symbol, and must not be match with any reserved system usernames (See: https://salsa.debian.org/installer-team/user-setup/raw/master/reserved-usernames).\n\nUsername for your account:" 0 0 3>&1 1>&2 2>&3)
            if [ $? -eq 0 ]; then
                if printf "%s" "$USER_NAME" | grep -Eoq "^[a-z][a-z0-9-]*$" && [ "${#USER_NAME}" -lt 33 ]; then
                    if grep -Fxq "$USER_NAME" "./reserved_usernames"; then
                        dialog --backtitle "$bt" --title "$usrtt" --msgbox "ERROR: The username you entered ($USER_NAME) is reserved for use by the system. Please select a different one." 0 0
                    else 
                        usrpswd_match=false
                        while ! $usrpswd_match; do
                            input=$(dialog --backtitle "$bt" --title "$usrtt" --clear --stdout --nocancel --insecure --passwordbox "Create a password for '$USER_NAME':" 0 0)
                            confirm_input=$(dialog --backtitle "$bt" --title "$usrtt" --clear --stdout --insecure --passwordbox "Re-enter password to verify:" 0 0)
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
            input=$(dialog --backtitle "$bt" --title "$usrtt" --clear --stdout --nocancel --insecure --passwordbox "Please set a password for 'root' (root is the Super User, the Administaion of the system, who grants permissions for you to do system jobs).\n\nRoot password:" 0 0)
            confirm_input=$(dialog --backtitle "$bt" --title "$usrtt" --clear --stdout --insecure --passwordbox "Re-enter password to verify:" 0 0)
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
            break
        else
            dialog --backtitle "$bt" --title "$usrtt" --msgbox "ERROR: You entered an invalid hostname.\n\nA valid hostname may contain only the numbers 0-9, upper and lowercase letters (A-Z and a-z), and the minus sign. It must be at most 63 characters long, and may not begin or end with a minus sign." 0 0
        fi
    done
    usrdone="*"
}
diskchoose() {
    diskconfirm=0
    while true; do
        disk=$(dialog --backtitle "$bt" --title "Partition the harddrive" --stdout --cancel-label "Exit to Menu" --menu "Disk/partition options" 0 0 0 \
            "Auto" "Automatically choosing disk and partition to install (alongside other operating systems)" \
            "Basic" "Choose (a) disk/partition(s) to install" \
            "DIY " "Manually layout the disks and partitions")
        case "$disk" in
            "Auto") ;;
            "Basic") disksel
                if [ $diskconfirm -eq 1 ]; then
                    break
                fi ;;
            "DIY ") clear
                printf "Use 'fdisk', 'cfdisk', 'parted' commands or any CLI-based disk utilities to edit the disks/partitions\n"
                printf "\n"
                printf "Type 'exit' after you have done all the jobs\n"
                printf "\n"
                $SHELL
                disksel
                break ;;
            *) menusel ;;
        esac
    done
}
disksel() {
    for device in $(lsblk -n -p -r -e 7,11 -o NAME); do
        device_size=$(lsblk -n -r -o SIZE "$device")
        block_devices+=("$device" "$device_size")
    done
    while true; do
        devdisk=$(dialog --backtitle "$bt" --title "Partition the harddrive" --stdout --cancel-label "Back" --menu "Select the disk for ExtOS to be installed on. Note that the disk you select will be erased, but not until you have confirmed the changes.\n\nSelect the disk in the list below:" 0 0 0 "${block_devices[@]}")
        if [ $? -eq 0 ]; then
            if dialog --backtitle "$bt" --title "Partition the harddrive" --cancel-label "Back" --yesno "Warning: All data on $(lsblk -d -n -r -o TYPE $devdisk) $devdisk will be erased\n\nContinue?" 0 0 ; then
                diskconfirm=1
                break
            fi
        else
            unset block_devices
            break
        fi
    done
    pttdone="*"
}
ossel() {
    osbs=$(dialog --backtitle "$bt" --title "$tt" --stdout --cancel-label "Back" --menu "Choose based distro" 0 0 0 1 "Arch-based" 2 "Debian/Ubuntu-based")
    if [ $osbs -eq 1 ]; then
        ostp=1
        pac
    elif [ $osbs -eq 2 ]; then
        ostp=2
        deb
    fi
}
deb() {
    debdist=$(dialog --backtitle "$bt" --title "$tt" --stdout --cancel-label "Back" --radiolist "$distrose" 0 0 0 \
        1 "Ubuntu          amd64/x86_64    21.04 lts       systemd" on \
        2 "Devuan(Debian)  amd64/x86_64    Beowulf         openrc " off \
        3 "Devuan(Debian)  amd64/x86_64    Beowulf         runit  " off \
        4 "Debian          i386/i686/x86   buster          systemd" off \
        5 "Devuan(Debian)  i386/i686/x86   Beowulf         openrc " off \
        6 "Devuan(Debian)  i386/i686/x86   Beowulf         runit  " off )
    echo $debdist >> ./out
}
pac() {
    pacdist=$(dialog --backtitle "$bt" --title "$tt" --stdout --cancel-label "Back" --radiolist "$distrose" 0 0 0 \
        1 "Arch Linux      amd64/x86_64    rolling         systemd" on \
        2 "Artix(Arch)     amd64/x86_64    rolling         openrc " off \
        3 "Artix(Arch)     amd64/x86_64    rolling         runit  " off \
        4 "Arch Linux 32   i386/i686/x86   rolling         systemd" off \
        5 "Parabola(Arch)  i386/i686/x86   rolling-xtended openrc " off \
        6 "Obarun(Arch)    i386/i686/x86   rolling-xtended s6/66  " off )
    echo $pacdist >> ./out
}
poweropts() {
    pwvar=$(dialog --backtitle "$bt" --title "Power options" --cancel-label "Back" --stdout --menu "Choose option to continue:" 0 0 0 \
        "Reboot   " "Restart the machine and also the installer" \
        "Sleep    " "Suspend the machine and save current state to RAM/swap" \
        "Hibernate" "Hibernate the machine and save current state to disk/RAMdisk" \
        "Shutdown " "Exit the installer and power off the  machine")
    case $pwvar in
        "Reboot   ") systemctl reboot ;;
        "Sleep    ") systemctl suspend;;
        "Hibernate") systemctl hibernate;;
        "Shutdown ") systemctl poweroff;;
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
            *) reset ; exit ;;
        esac
    done
}
main() {
    netinit
    dircheck
    keymapc
    localec
    localtz
    usrname
    diskchoose
    ossel
}
if dialog --backtitle "$bt" --title "$tt" --yesno "This is ExtOS linux respin v0.1\nMade by Shadichy\n\nStart installation process?" 0 0
then
#    main
    menusel
else
    clear
    printf "Run ./install.sh to restart the installer\n"
    exit
fi
echo "let's continue"
#locale=$( dialog --backtitle "$bt" --title "$tt" --msgbox "check" 10 40 3>&1 1>&2 2>&3 3>&- )
#echo "$locale" >> ./out