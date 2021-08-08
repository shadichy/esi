#!/bin/bash

if dialog --backtitle "ExtOS-respin Installer" --title "Installing progress" --yesno "This is ExtOS linux respin v0.1\nMade by Shadichy\n\nStart installation process?" 20 50
then
    if [ ! -d ~/esi ] && [ ! -d ./esi ] && [ ! -d ../esi ]; then
        git clone https://github.com/shadichy/esi.git
    fi
else
    exit
fi
echo aft
locale=$( dialog --backtitle "ExtOS-respin Installer" --title "Installing progress" --check 3>&1 1>&2 2>&3 3>&- )
echo "$locale" >> ./out
user_input=$( dialog --title "Create Directory"          --inputbox "Enter the directory name:" 8 40 3>&1 1>&2 2>&3 3>&- )

    echo "$user_input" >> ./out