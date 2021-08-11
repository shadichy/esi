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
        if [ ! -d ~/esi ] && [ ! -d ./esi ] && [ ! -d ../esi ]; then
            git clone https://github.com/shadichy/esi.git
        fi
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
        printf "\e[0mType 'exit' to continue\n"
        printf "\n"
        $SHELL
        nct=1
        netinit
    fi
}
keymapc() {
    while true; do
        KEYMAP=$(dialog --title "Set the Keyboard Layout" --nocancel --default-item "us" --menu "Select a keymap that corresponds to your keyboard layout. Choose 'other' if your keymap is not listed. If you are unsure, the default is 'us' (United States/QWERTY).\n\nKeymap:" 22 57 10 \
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
            KEYMAP=$(dialog --title "Set the Keyboard Layout" --cancel-label "Back" --menu "Select a keymap that corresponds to your keyboard layout. The default is 'us' (United States/QWERTY)." 30 60 25 "${keymaps[@]}" 3>&1 1>&2 2>&3)
            if [ $? -eq 0 ]; then
                break
            fi
        else
            break
        fi
    done
    dialog --infobox "Setting keymap to $KEYMAP..." 3 50
    localectl set-keymap "$KEYMAP"
    loadkeys "$KEYMAP"
    keydone="*"
}
localec() {
    while true; do
        LOCALE=$(dialog --title "Set the System Locale" --nocancel --default-item "en_US.UTF-8" --menu "Select a locale that corresponds to your language and region. The locale you select will define the language used by the system and other region specific information. Choose 'other' if your language and/or region is not listed. If you are unsure, the default is 'en_US.UTF-8'.\n\nLocale:" 30 65 16 \
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
            LOCALE=$(dialog --title "Set the System Locale" --cancel-label "Back" --menu "Select a locale that corresponds to your language and region. The locale you select will define the language used by the system and other region specific information. If you are unsure, the default is 'en_US.UTF-8'.\n\nLocale:" 30 65 16 "${locales[@]}" 3>&1 1>&2 2>&3)
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
        ZONE=$(dialog --title "Set the Time Zone" --nocancel --menu "Select your time zone.\nIf your region is not listed, select 'other'.\n\nTime zone:" 27 50 17 "${regions[@]}" 3>&1 1>&2 2>&3)
        if [ "$ZONE" != "other" ]; then
            zone_regions=()
            for zone_region in $(find /usr/share/zoneinfo/"${ZONE}" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort); do
                zone_regions+=("$zone_region" "")
            done
            SUBZONE=$(dialog --title "Set the Time Zone" --cancel-label "Back" --menu "Select your time zone.\n\nTime zone:" 27 50 17 "${zone_regions[@]}" 3>&1 1>&2 2>&3)
            if [ $? -eq 0 ]; then
                if [ -d /usr/share/zoneinfo/"${ZONE}/${SUBZONE}" ]; then
                    subzone_regions=()
                    for subzone_region in $(find /usr/share/zoneinfo/"${ZONE}/${SUBZONE}" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort); do
                        subzone_regions+=("$subzone_region" "")
                    done
                    SUBZONE_SUBREGION=$(dialog --title "Set the Time Zone" --cancel-label "Back" --menu "Select your time zone.\n\nTime zone:" 27 50 17 "${subzone_regions[@]}" 3>&1 1>&2 2>&3)
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
            ZONE=$(dialog --title "Set the Time Zone" --cancel-label "Back" --menu "Select your time zone.\n\nTime zone:" 27 50 17 "${other_regions[@]}" 3>&1 1>&2 2>&3)
            if [ $? -eq 0 ]; then
                ZONE="${ZONE}"
                break
            fi
        fi
    done
    dialog --title "Set the Hardware Clock" --nocancel --yesno "Would you like to set the hardware clock from the system clock using UTC time?\nIf you select no, local time will be used instead.\n\nIf you are unsure, UTC time is the default." 8 85
    if [ $? -ne 0 ]; then
        utc_enabled=false
    fi
    tzcdone="*"
}
diskchoose() {
    disk=$(dialog --backtitle "$bt" --title "$tt" --stdout --cancel-label "Back" --menu "Disk/partition options" 0 0 0 1 "Open partition editor tool" 2 "Select disk and install")
    if [ $disk -eq 1 ]; then
        clear
        printf "Use 'fdisk' or 'parted' commands to edit the disks/partitions\n"
        printf "\n"
        printf "Type 'exit' to continue\n"
        printf "\n"
        $SHELL
        disksel
    elif [ $disk -eq 2 ]; then
        disksel
    else
        menusel
    fi
}
disksel() {
    clear
    fdisk -l
    printf "\nex: Type in '/dev/sda', '/dev/hdb2', 'xvda1', vdc3', 'nvme0n3p2',... ('full path and name' or 'name only', no brackets), or whatever nvme, disk, sdcard, virtual mem or specify any partions exist in the list above\n\n"
    read -p "Choose disk/partition to install: " diskmnt
    if [ -b "/dev/$diskmnt" ]; then
        disktaget="/dev/$diskmnt"
    elif [ -b $diskmnt ]; then
        disktaget=$diskmnt
    elif [ $diskmnt == "exit" ] || [ $diskmnt == "quit" ] || [ $diskmnt == "q" ]; then
        diskchoose
    elif [ -b "/dev/$diskmnt" ] || [ ! -b $diskmnt ]; then
        printf "Invalid disk/partition path/name"
        sleep 3
        disksel
    fi
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
        3 "Arch Linux 32   i386/i686/x86   rolling         systemd" off \
        3 "Parabola(Arch)  i386/i686/x86   rolling-xtended openrc " off \
        3 "Obarun(Arch)    i386/i686/x86   rolling-xtended s6/66  " off )
    echo $pacdist >> ./out
}
menusel() {
    while true; do
    choice=$(dialog --title "Main Menu" --nocancel \
        --menu "Select an option below using the UP/DOWN, PLUS(+) or MINUS(-) keys and SPACE or ENTER. \
         \n  JOBS         DESCRIBE                             Done" 19 70 11 \
            "NETWORK    " "Manually config the network           $netdone   " \
            "KEYMAP     " "Set the keyboard layout               $keydone   " \
            "LOCALE     " "Set the system locale                 $locdone   " \
            "TIMEZONE   " "Set the system time zone              $tzcdone   " \
            "CREATE USER" "Create your user account              $usrdone   " \
            "PARTITION  " "Partition the installation drive      $pttdone   " \
            "INSTALL    " "Install ExtOS Linux respin                       " \
            "REBOOT     " "Reboot system                                    " \
            "EXIT       " "Exit the installer                               " \
            3>&1 1>&2 2>&3)
        case "$choice" in
            "NETWORK    ") netmes="\e[0mFrom here you'll configure the network manually"; netcheck ;;
            "KEYMAP     ") keymapc ;;
            "LOCALE     ") localec ;;
            "TIMEZONE   ") localtz ;;
            "CREATE USER") usrname ;;
            "PARTITION  ") diskchoose ;;
            "INSTALL    ") ossel ;;
            "REBOOT     ") systemctl reboot ;;
            *) reset ; exit ;;
        esac
    done
}
main() {
    netinit
    keymapc
    localtz
    diskchoose
    ossel
}
if dialog --backtitle "$bt" --title "$tt" --yesno "This is ExtOS linux respin v0.1\nMade by Shadichy\n\nStart installation process?" 0 0
then
    main
    menusel
else
    clear
    printf "Run ./install.sh to restart the installer\n"
    exit
fi
echo "let's continue"
#locale=$( dialog --backtitle "$bt" --title "$tt" --msgbox "check" 10 40 3>&1 1>&2 2>&3 3>&- )
#echo "$locale" >> ./out