#!/bin/bash
net=0
nct=0
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
    disk=$( dialog --backtitle 'ExtOS-respin Installer' --title 'Installing progress' --stdout --menu "Disk/partition options" 10 40 10 1 "Open partition editor tool" 2 "Select disk and install" )
    if [ $disk -eq 1 ]; then
        clear
        printf "Use 'fdisk' or 'parted' commands to edit the disks/partitions\n"
        printf "\n"
        printf "Type 'exit' to continue\n"
        printf "\n"
        $SHELL
    elif [ $disk -eq 2 ]; then
        dialog --backtitle 'ExtOS-respin Installer' --title 'Installing progress' --msgbox 'nah' 10 40
    else
        net=0
        netinit
    fi
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
            if dialog --backtitle 'ExtOS-respin Installer' --title 'Installing progress' --yesno "Continue without network?" 10 40 ; then
                net=1
                diskchoose
            fi
        fi
        netcheck
    fi
}
if dialog --backtitle 'ExtOS-respin Installer' --title 'Installing progress' --yesno "This is ExtOS linux respin v0.1\nMade by Shadichy\n\nStart installation process?" 20 50
then
    netinit
else
    echo "Run ./install.sh to restart the installer"
    exit
fi
echo "let's continue"
#locale=$( dialog --backtitle "ExtOS-respin Installer" --title "Installing progress" --msgbox "check" 10 40 3>&1 1>&2 2>&3 3>&- )
#echo "$locale" >> ./out