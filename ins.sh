#!/bin/bash
net=0
nct=0
workdir=$(pwd)
bt="ExtOS-respin Installer"
tt="Installing progres"
netcheck () {
    if [ $net -eq 0 ]; then
        clear
        printf "\e[1;31mYou'll need to configure the network before installing or else some packages will be broken\n"
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
diskchoose () {
    disk=$(dialog --backtitle "$bt" --title "$tt" --stdout --menu "Disk/partition options" 0 0 0 1 "Open partition editor tool" 2 "Select disk and install")
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
        net=0
        netinit
    fi
}
disksel () {
    clear
    fdisk -l
    printf "\nex: Type in '/dev/sda', '/dev/hdb2', 'xvda1', vdc3', 'nvme0n3p2',... ('full path and name' or 'name only', no brackets), or whatever nvme, disk, sdcard, virtual mem or specify any partions exist in the list above\n\n"
    read -p "Choose disk/partition to install: " diskmnt
    if [ -b "/dev/$diskmnt" ]; then
        disktaget="/dev/$diskmnt"
        ossel
    elif [ -b $diskmnt ]; then
        disktaget=$diskmnt
        ossel
    elif [ $diskmnt == "exit" ] || [ $diskmnt == "quit" ] || [ $diskmnt == "q" ]; then
        diskchoose
    elif [ -b "/dev/$diskmnt" ] || [ ! -b $diskmnt ]; then
        printf "Invalid disk/partition path/name"
        sleep 3
        disksel
    fi
}
ossel () {
    dialog --backtitle "$bt" --title "$tt" --menu 0 0 0 1 "Arch-based" 2 "Ubuntu-based"
    echo lol
}
netinit () {
    if wget -q --spider http://archlinux.org; then
        net=2
        nct=0
        if [ ! -d ~/esi ] && [ ! -d ./esi ] && [ ! -d ../esi ]; then
            git clone https://github.com/shadichy/esi.git
        fi
        diskchoose
    else
        if [ $nct -eq 1 ]; then
            if dialog --backtitle "$bt" --title "$tt" --yesno "Continue without network?" 0 0 ; then
                net=1
                diskchoose
            fi
        fi
        netcheck
    fi
}
if dialog --backtitle "$bt" --title "$tt" --yesno "This is ExtOS linux respin v0.1\nMade by Shadichy\n\nStart installation process?" 0 0
then
    netinit
else
    clear
    printf "Run ./install.sh to restart the installer"
    exit
fi
echo "let's continue"
#locale=$( dialog --backtitle "$bt" --title "$tt" --msgbox "check" 10 40 3>&1 1>&2 2>&3 3>&- )
#echo "$locale" >> ./out