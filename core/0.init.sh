#!/bin/bash

if [ "$EUID" != 0 ]; then
  dialog --backtitle "$BACKTITLE" --title "ERROR" --msgbox "Please run this script as root."
  exit
fi

LABEL="EXTOS"

CONNECTED=0
OFFLINE=0
is64=0
diskconfirm=0
ZONEINFO_PATH=/usr/share/zoneinfo

BACKTITLE="ExtOS-respin Installer"
TITLE="Installing progress"

NET_STAT=""
KEY_STAT=""
LOC_STAT=""
TZC_STAT=""
USR_STAT=""
PRT_STAT=""
OS_STAT=""

MNT_LST=("")

sfs_srv="https://example.com"

INIT_SYSTEM=loginctl
pidof systemd && INIT_SYSTEM=systemctl

BIOSMODE="bios"
[ -d /sys/firmware/efi ] && BIOSMODE="uefi"

say() { printf "%s" "$*"; }
saybr() { say "$*\n"; }

init() {
	case $(lscpu | grep Arch | awk '{print "$2"}') in
	"x86_64") is64=1 ;;
	"x86") is64=0 ;;
	*)
		dialog --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "Your CPU is not supported, please install on another computer"
		exit 1
		;;
	esac
	if curl -I http://archlinux.org || wget -q --spider http://archlinux.org || nc -zw1 archlinux.org 80; then
		CONNECTED=2
		OFFLINE=0
		NET_STAT="*"
		return
	fi
	[ $OFFLINE = 1 ] && dialog --backtitle "$BACKTITLE" --title "$TITLE" --yesno "Continue without network?" 0 0 && CONNECTED=1
	NET_MSG="\e[1;31mYou'll need to configure the network before installing or else some packages will be broken"
	netcheck
}

dircheck() {
	workdir=$(find / -type d -iname "esi" 2>/dev/null | head -1)
	if [ "$workdir" ]; then
		cd "$workdir"
	elif [ $CONNECTED = 2 ]; then
		git clone https://github.com/shadichy/esi.git
		cd ./esi
		workdir=$(pwd)
	fi
}
