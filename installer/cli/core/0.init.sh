#!/bin/bash

BACKTITLE="ExtOS-respin Installer"
TITLE="Installing progress"

if [ "$EUID" != 0 ]; then
	dialog --backtitle "$BACKTITLE" --title "ERROR" --msgbox "Please run this script as root." 0 0
	exit
fi

LABEL="EXTOS"

CONNECTED=0
OFFLINE=0
is64=0
diskconfirm=0
ZONEINFO_PATH=/usr/share/zoneinfo

NET_STAT=""
KEY_STAT=""
LOC_STAT=""
TZC_STAT=""
USR_STAT=""
PRT_STAT=""
OS_STAT=""

MNT_LST=("")

SFS_SRV=example.com
URL=https://$SFS_SRV

INIT_SYSTEM=loginctl
pidof systemd && INIT_SYSTEM=systemctl

BIOSMODE="bios"
[ -d /sys/firmware/efi ] && BIOSMODE="uefi"

title=$TITLE

alias say=printf
saybr() { say "$*\n"; }
die() {
	[ "$*" ] && saybr "ERROR: $*"
	reset
	saybr "Run $0 again to restart the installer"
	exit 1
}
dbox() { dialog --backtitle "$BACKTITLE" --title "$title" --stdout "$@"; }
yesnobox() { dbox --yesno "$*" 0 0; }
msgbox() { dbox --msgbox "$*" 0 0; }
pwdbox() { dbox --clear --insecure "$1" --passwordbox "${*#"$1"}" 0 0; }
pwdbox_c() { pwdbox "--nocancel" "$*"; }
infobox() { dbox --infobox "$*" 0 0; }
# warnbox() { msgbox "WARNING: $*"; }
errbox() { msgbox "ERROR: $*"; }
wraptt() {
	local old_title=$title
	title=$1
	shift
	"$@"
	local code=$?
	title=$old_title
	return $code
}

init() {
	case $(lscpu | grep Arch | awk '{print "$2"}') in
	"x86_64") is64=1 ;;
	"x86") is64=0 ;;
	*)
		errbox "Your CPU is not supported, please install on another computer"
		exit 1
		;;
	esac
	netcheck
}
