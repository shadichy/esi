#!/bin/bash
BACKTITLE="ExtOS-respin Installer"
TITLE="Installing progress"
if [ "$EUID" != 0 ];then
dialog --backtitle "$BACKTITLE" --title ERROR --msgbox "Please run this script as root." 0 0
exit
fi
LABEL=EXTOS
CONNECTED=0
OFFLINE=0
is64=0
diskconfirm=0
ZONEINFO_PATH=/usr/share/zoneinfo
NET_STAT=
KEY_STAT=
LOC_STAT=
TZC_STAT=
USR_STAT=
PRT_STAT=
OS_STAT=
MNT_LST=()
SFS_SRV=example.com
URL=https://$SFS_SRV
INIT_SYSTEM=loginctl
pidof systemd&&INIT_SYSTEM=systemctl
BIOSMODE=bios
[ -d /sys/firmware/efi ]&&BIOSMODE=uefi
title=$TITLE
alias say=printf
saybr(){ say "$*\n";}
die(){
[ "$*" ]&&saybr "ERROR: $*"
reset
saybr "Run $0 again to restart the installer"
exit 1
}
dbox(){ dialog --backtitle "$BACKTITLE" --title "$title" --stdout "$@";}
yesnobox(){ dbox --yesno "$*" 0 0;}
msgbox(){ dbox --msgbox "$*" 0 0;}
infobox(){ dbox --infobox "$*" 0 0;}
errbox(){ msgbox "ERROR: $*";}
wraptt(){
local old_title=$title
title=$1
shift
"$@"
local code=$?
title=$old_title
return $code
}
init(){
case $(lscpu|grep Arch|awk '{print "$2"}') in
x86_64)is64=1;;x86)is64=0;;*)errbox "Your CPU is not supported, please install on another computer"
exit 1;;esac
netcheck
}
netcheck(){
while true;do
if curl -I "$URL"||wget -q --spider "$URL"||nc -zw1 "$SFS_SRV" 80;then
CONNECTED=2
OFFLINE=0
NET_STAT="*"
return
fi
[ "$OFFLINE" = 1 ]&&yesnobox "Continue without network?"&&CONNECTED=1
NET_MSG="\e[1;31mYou'll need to configure the network before installing or else some packages will be broken"
[ "$CONNECTED" = 0 ]||break
clear
saybr "$NET_MSG"
saybr
saybr
saybr "\e[1;32mQuick guide:"
saybr
saybr "\e[1;33m (For more 'space': Press Ctrl + Alt + F2 switching to TTY2 (Ctrl + Alt + F1 to get back) or open a new terminal window/tab/session(tmux))\e[1;36m"
saybr
saybr "\tRun command 'ip link' to check enabled network interfaces"
saybr "\tRun command 'rfkill list all' to list blocked network card and 'rfkill unblock all' to unblock all Soft-blocked network card"
saybr "\tRun command 'iwctl' or 'wpa_cli' to configure wireless connection"
saybr "\tRun command 'mmcli' to configure mobile network"
saybr
saybr "\e[1;35m Finally, 'ping' some websites to check if it works or not"
saybr
saybr
saybr "\e[0mType 'exit' after you have done all the jobs"
saybr
$SHELL
OFFLINE=1
done
}
dircheck(){
find ./ -type d -iname esi -print -quit -exec cd {} \;||[ "$CONNECTED" = 2 ]&&git clone https://github.com/shadichy/esi.git&&cd ./esi&&WORKDIR=$(pwd)||die "Network unavailable, can't fetch installation needs"
}
keymapc(){
title="Set the Keyboard Layout"
while true;do
KEYMAP=$(dbox --nocancel --default-item us --menu "Select a keymap that corresponds to your keyboard layout. Choose 'other' if your keymap is not listed. If you are unsure, the default is 'us' (United States/QWERTY).\n\nKeymap:" 0 0 0 br-abnt2 "Brazilian Portuguese" cf Canadian-French colemak "Colemak (US)" dvorak "Dvorak (US)" fr-latin1 French de-latin1 German gr Greek it Italian hu Hungarian jp Japanese pl Polish pt-latin9 Portuguese ru4 Russian es Spanish la-latin1 "Spanish Latinoamerican" sv-latin1 Swedish us "United States" uk "United Kingdom" other "View all available keymaps")
[ "$KEYMAP" = other ]||break
keymaps=()
for map in $(localectl list-keymaps);do
keymaps+=("$map" "")
done
KEYMAP=$(dbox --cancel-label Back --menu "Select a keymap that corresponds to your keyboard layout. The default is 'us' (United States/QWERTY)." 0 0 0 "${keymaps[@]}")&&break
done
localectl set-keymap "$KEYMAP"
loadkeys "$KEYMAP"
KEY_STAT="*"
}
localec(){
title="Set the System Locale"
menu_title(){ say "Select a locale that corresponds to your language and region. The locale you select will define the language used by the system and other region specific information. $* If you are unsure, the default is 'en_US\.UTF-8'\.\\n\\nLocale:";}
while true;do
LOCALE=$(dbox --nocancel --default-item en_US.UTF-8 --menu "$(menu_title "Choose 'other' if your language and/or region is not listed.") " 0 0 0 en_AU.UTF-8 "English (Australia)" en_CA.UTF-8 "English (Canada)" en_US.UTF-8 "English (United States)" en_GB.UTF-8 "English (Great Britain)" fr_FR.UTF-8 "French (France)" de_DE.UTF-8 "German (Germany)" it_IT.UTF-8 "Italian (Italy)" ja_JP.UTF-8 "Japanese (Japan)" pt_BR.UTF-8 "Portuguese (Brazil)" pt_PT.UTF-8 "Portuguese (Portugal)" ru_RU.UTF-8 "Russian (Russia)" es_MX.UTF-8 "Spanish (Mexico)" es_ES.UTF-8 "Spanish (Spain)" sv_SE.UTF-8 "Swedish (Sweden)" vi_VN.UTF-8 "Vietnamese (Vietnam)" zh_CN.UTF-8 "Chinese (Simplified)" other "View all available locales")
[ "$LOCALE" = other ]||break
locales=()
while read -r line;do
locales+=("$line" "")
done< <(grep -E "^#?[a-z].*UTF-8" /etc/locale.gen|sed -e 's/#//' -e 's/\s.*$//')
LOCALE=$(dbox --cancel-label Back --menu "$(menu_title)" 0 0 0 "${locales[@]}")&&break
done
LOC_STAT="*"
}
localtz(){
utc_enabled=true
title="Set the Time Zone"
menu_title(){ say "Select your time zone.\n$*\nTime zone:";}
regions=()
for region in $(find "$ZONEINFO_PATH" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'|grep -E -v '/$|posix|right'|sort);do
regions+=("$region" "")
done
regions+=(other "")
while true;do
ZONE=$(dbox --nocancel --menu "$(menu_title "If your region is not listed, select 'other'.\n")" 0 0 0 "${regions[@]}")
if [ "$ZONE" = other ];then
for other_region in $(find "$ZONEINFO_PATH" -mindepth 1 -maxdepth 1 -type f -printf '%f\n'|grep -E -v '/$|iso3166.tab|leapseconds|posixrules|tzdata.zi|zone.tab|zone1970.tab'|sort);do
other_regions+=("$other_region" "")
done
ZONE=$(dbox --cancel-label Back --menu "$(menu_title "")" 0 0 0 "${other_regions[@]}")&&break
fi
zone_regions=()
for zone_region in $(find "$ZONEINFO_PATH"/"${ZONE}" -mindepth 1 -maxdepth 1 -printf '%f\n'|sort);do
zone_regions+=("$zone_region" "")
done
SUBZONE=$(dbox --cancel-label Back --menu "$(menu_title "")" 0 0 0 "${zone_regions[@]}")||continue
if [ ! -d "$ZONEINFO_PATH"/"${ZONE}/${SUBZONE}" ];then
ZONE="${ZONE}/${SUBZONE}"
break
fi
subzone_regions=()
for subzone_region in $(find "$ZONEINFO_PATH"/"${ZONE}/${SUBZONE}" -mindepth 1 -maxdepth 1 -printf '%f\n'|sort);do
subzone_regions+=("$subzone_region" "")
done
SUBZONE_SUBREGION=$(dbox --cancel-label Back --menu "$(menu_title "")" 0 0 0 "${subzone_regions[@]}")&&ZONE="${ZONE}/${SUBZONE}/${SUBZONE_SUBREGION}"&&break
done
title="Set the Hardware Clock"
dbox --nocancel --yesno "Would you like to set the hardware clock from the system clock using UTC time?\nIf you select no, local time will be used instead.\n\nIf you are unsure, UTC time is the default." 0 0||utc_enabled=false
TZC_STAT="*"
}
reserved_usernames=(
root
daemon
bin
sys
sync
games
man
lp
mail
news
uucp
proxy
www-data
backup
list
irc
gnats
nobody
adm
tty
disk
kmem
dialout
fax
voice
cdrom
floppy
tape
sudo
audio
dip
operator
src
shadow
utmp
video
sasl
plugdev
staff
users
nogroup
netplan
ftn
mysql
tac-plus
alias
qmail
qmaild
qmails
qmailr
qmailq
qmaill
qmailp
asterisk
vpopmail
vchkpw
slurm
hacluster
haclient
grsec-tpe
grsec-sock-all
grsec-sock-clt
grsec-sock-srv
grsec-proc
ceph
opensrf
libvirt-qemu
admin
Debian-exim
bind
crontab
cupsys
dcc
dhcp
dictd
dnsmasq
dovecot
fetchmail
firebird
ftp
fuse
gdm
haldaemon
hplilp
identd
jwhois
klog
lpadmin
messagebus
mythtv
netdev
powerdev
radvd
saned
sbuild
scanner
slocate
ssh
sshd
ssl-cert
sslwrap
statd
syslog
telnetd
tftpd
)
usrname(){
title="User Configurations"
local reserved_usrname_note="\n\nThe username must start with a lower-case letter, which can be followed by any combination of numbers, more lower-case letters, or the dash symbol, must be no more than 32 characters long, and must not be match with any reserved system usernames (See: https://salsa.debian.org/installer-team/user-setup/raw/master/reserved-usernames)."
while true;do
FULL_NAME=$(dbox --nocancel --inputbox "The installer will create a user account for you. This is the main user account that you will login to and use for non-administrative activities.\n\nPlease enter the real name for this user. This information will be used for any program that uses the user's real name such as email. Entering your full name here is recommended;however, it may be left blank.\n\nFull name for the new user:" 0 0)
while true;do
USER_NAME=$(dbox --cancel-label Back --inputbox "Please enter a username for the new account. $reserved_usrname_note\n\nUsername for your account:" 0 0 user)||continue
if ! say "$USER_NAME"|grep -Eoq "^[a-z][a-z0-9-]*$"&&[ "${#USER_NAME}" -lt 33 ];then
errbox "You entered an invalid username. $reserved_usrname_note"
continue
fi
if grep -Fxq "$USER_NAME"<<<"${reserved_usernames[*]}";then
errbox "The username you entered ($USER_NAME) is reserved for use by the system. Please select a different one."
continue
fi
usrpswd_match=false
while ! "$usrpswd_match";do
input=$(dbox --clear --nocancel --insecure --passwordbox "Note: the default password of '$USER_NAME' is 'extos'\n\nCreate a new password for '$USER_NAME':" 0 0 extos)
if [ "$input" = extos ];then
confirm_input=extos
else
confirm_input=$(dbox --clear --insecure --passwordbox "Re-enter password to verify:" 0 0)
fi
if [ ! "$input" ];then
errbox "You are not allowed to have an empty password."
elif [ "$input" != "$confirm_input" ];then
errbox "The two passwords you entered did not match."
else
user_passwd="$input"
usrpswd_match=true
fi
done
break
done
if yesnobox "Do you want to set a password for 'root' (root is the Super User, the Administaion of the system, who grants permissions for you to do system jobs)?";then
supswd_match=false
while ! "$supswd_match";do
input=$(dbox --clear --nocancel --insecure --passwordbox "Note: the default is 'root'\n\nEnter root password:" 0 0 root)
if [ "$input" = root ];then
confirm_input=root
else
confirm_input=$(dbox --clear --insecure --passwordbox "Re-enter password to verify:" 0 0)
fi
if [ -z "$input" ];then
errbox "You are not allowed to have an empty password."
elif [ "$input" != "$confirm_input" ];then
errbox "The two passwords you entered did not match."
else
root_passwd="$input"
supswd_match=true
fi
done
fi
HOST_NAME=$(dbox --nocancel --inputbox "Please enter the hostname for this system.\n\nThe hostname is a single word that identifies your system to the network.\n\nHostname:" 0 0 ExtOS)
if say "$HOST_NAME"|grep -Eoq "^[a-zA-Z0-9-]{1,63}$"&&[ "${HOST_NAME:0:1}" != - ]&&[ "${HOST_NAME: -1}" != - ];then
USR_STAT="*"
break
else
errbox "You entered an invalid hostname.\n\nA valid hostname may contain only the numbers 0-9, upper and lowercase letters (A-Z and a-z), and the minus sign. It must be at most 63 characters long, and may not begin or end with a minus sign."
fi
done
}
randstr(){ tr -dc 'a-zA-Z0-9'</dev/urandom|fold -w 8|head -n 1;}
ynwarn(){ dbox --extra-button --extra-label No --no-label Back --yesno "Warning: $*" 0 0;}
blk(){ lsblk -n -r "$@";}
blk_d(){
opt=$1
shift
blk -d -o "$opt" "$@"
}
blk_p(){
opt=$1
shift
blk -p -o "$opt" "$@"
}
blk712(){
opt=$1
shift
blk_p "$opt" -e 7,11,251 "$@"
}
mount_check(){
umount -R /mnt* 2>/dev/null
umount -R /mnt 2>/dev/null
free|awk '/^Swap:/ {exit !"$2"}'&&swapoff -a
vgchange -ay
}
disklst(){
unset devs
for dev in $(blk712 NAME -M);do
[ "$(blk_d MOUNTPOINT "$dev")" ]&&continue
devmp=" "
hasmntpt=$(grep -w "$dev"<<<"${MNT_LST[@]}")
[ "$hasmntpt" ]&&devmp=$(echo "$hasmntpt"|awk '{print "$2"}')
devs+=("$dev"$'\t'"" "$(blk_d TYPE "$dev")"$'\t'"$(blk_d FSTYPE "$dev")"$'\t'"$(blk_d SIZE "$dev")"$'\t'"$devmp")
done
}
create_part(){
while IFS= read -r f;do
part_size=$(echo "$f"|awk '{print "$3"}')
((${part_size%MiB}<=4096))&&continue
part_start=$(say "$f"|awk '{print "$1"}')
part_end=$(say "$f"|awk '{print "$2"}')
part_table_before=("$(blk712 NAME "$1")")
printf "fix\n"|parted ---pretend-input-tty "$1" mkpart "$part_type" ext4 "$part_start" "$part_size"||continue
part_table_after=("$(blk712 NAME "$1")")
part_id=$(echo "${part_table_before[*]} ${part_table_after[*]}"|tr ' ' '\n'|sort -u)
[ "$part_table" = msdos ]&&! printf "fix\n"|parted ---pretend-input-tty "$part_id" -name "$LABEL"&&continue
mkfs.ext4 -L "$LABEL" "$part_id"
e2fsck -f "$part_id"
MNT_LST=("$part_id /")
diskconfirm=1
done<<<"$(printf "fix\n"|parted ---pretend-input-tty "$1" unit MiB print free|grep "Free Space")"
}
diskchoose(){
diskconfirm=0
title="Partition the harddrive"
while true;do
disk=$(dbox --cancel-label "Exit to Menu" --menu "Disk/partition options" 0 0 0 Auto "Automatically choosing disk and partition to install (alongside other operating systems)" Basic "Select disk/partition(s) to install" Manual "Customize disk/partition layout")
case "$disk" in
Auto)for d in $(blk712 NAME -d);do
part_table=$(printf "fix\n"|parted ---pretend-input-tty "$d" print|grep "Partition Table"|awk '{print "$3"}')
case "$part_table" in
gpt)part_type="$LABEL";;msdos)part_type=primary;;*)continue;;esac
create_part "$d"
[ "$(grep -w "/"<<<"${MNT_LST[@]}"|awk '{print "$2"}')" ]&&break
for p in $(blk712 NAME "$d"|grep -vw "$d");do
[ "$(blk -o MOUNTPOINT "$p")" ]&&continue
part_fs=$(blk_d FSTYPE "$p")
[[ "$part_fs" =~ crypt.* ]]||[[ "$part_fs" =~ swap.* ]]||[[ "$part_fs" =~ LVM.* ]]||[[ "$part_fs" =~ raid.* ]]||[[ -z "$part_fs" ]]&&continue
mount "$p" /mnt||continue
if [ "$(df -m --output=avail /mnt|grep -v Avail)" -lt 4096 ];then
umount /mnt
continue
fi
umount /mnt
partinmb=$(printf "fix\n"|parted ---pretend-input-tty "$p" unit MiB print|grep -w 1|awk '{print "$3"}')
printf "fix\n"|parted ---pretend-input-tty "$p" resizepart 1 $((${partinmb%MiB} - 4096))||continue
create_part "$d"
[ $diskconfirm = 1 ]&&return
done
done;;Basic)local old_tt=$title
simplediskman
title=$old_tt
[ "$diskconfirm" = 1 ]&&return;;Manual)if wraptt "Manual partitioning" dbox --yes-label "Use Terminal interface" --no-label "Use Command line interface" --yesno "Would you like to use the terminal interface or the command line interface?" 0 0;then
advcd_diskman
[ "$diskconfirm" = 1 ]&&return
fi
clear
saybr
saybr
saybr "\e[1;32mQuick guide:"
saybr
saybr "\e[1;33m### Physical Disk/Partition Management ###\e[0m"
saybr "\e[1;36m"
saybr "\tUse 'lsblk' or 'blkid' to see the list of disks/partitions."
saybr "\tUse 'fdisk', 'cfdisk', 'parted' commands or any CLI-based disk utilities to manage disks/partitions"
saybr
saybr "\e[1;33m### Logical Volume Management ###\e[0m"
saybr "\e[1;36m"
saybr "\tUse pvdisplay, pvcreate, pvremove commands to manage Physical Volumes"
saybr "\tUse vgdisplay, vgcreate, vgremove commands to manage Volume Groups"
saybr "\tUse lvdisplay, lvcreate, lvremove commands to manage logical volumes"
saybr
saybr "\e[1;33m### Encrypted Volume Management ###\e[0m"
saybr "\e[1;36m"
saybr "\tUse cryptsetup commands to manage encrypted volumes"
saybr
saybr "\e[0mType 'exit' after you have done all the jobs"
saybr
$SHELL
advcd_diskman
[ "$diskconfirm" = 1 ]&&return;;*)menusel;;esac
done
}
append_comma(){ sed -r 's/\s+\//, \//gm'<<<"$*";}
simplediskman(){
mount_check
disklst
if [ ! "${devs[*]}" ];then
errbox "No device is available to install"
return 1
fi
while true;do
devdisk=$(dbox --cancel-label Back --ok-label Select --menu "Select the disk/partition for ExtOS to be installed on. Note that the disk/partition you select will be erased, but not until you have confirmed the changes.\n\nSelect the disk in the list below:" 0 80 0 "${devs[@]}")||break
devtype=$(blk_d TYPE "$devdisk")
case "$devtype" in
disk)dorpb="entire disk";;*)dorpb=partition;;esac
wraptt "Confirm install on $devdisk" yesnobox "Are you sure you want to install ExtOS on the $dorpb $devdisk?\n\nThis will erase all data on the $devdisk, and cannot be recovered." 0 0||continue
box "Swap is a partition that serves as overflow space for your RAM.\nSwap is not required for ExtOS to run, but it is recommended to use swap for better performance on low-end hardware or hibernation.\n\nDo you want to use swap?" 0 0
useswp=$?
title="Formatting $devdisk"
case "$devtype" in
part)rootfsdev="$devdisk"
infobox "Formatting $devdisk as ext4"
if ! mkfs.ext4 -F -L EXTOS "$devdisk";then
msgbox "Failed to format $devdisk"
continue
fi
MNT_LST+=("$devdisk /")
flagasboot(){
parted -s "$devdisk" set 1 boot on&&return
msgbox "Failed to set $devdisk as bootable"
continue
}
case $BIOSMODE in
uefi)ESP=$(lsblk -o NAME,LABEL,PARTLABEL|grep -w EFI|awk '{print "$1"}')
if [ "$ESP" ];then
MNT_LST+=("$ESP /boot/efi")
else
flagasboot
fi;;bios)flagasboot;;esac;;disk)infobox "Creating GPT partition table on $devdisk"
if ! parted -s "$devdisk" mklabel gpt;then
msgbox "Failed to create GPT partition table on $devdisk"
continue
fi
infobox "Creating EFI system partition"
if ! parted -s "$devdisk" mkpart primary fat32 1 100M;then
msgbox "Failed to create EFI system partition on $devdisk"
continue
fi
ESP=$(blk_p NAME "$devdisk"|grep -vw "$devdisk")
parted -s "$devdisk" name 1 EFI
parted -s "$devdisk" set 1 esp on
parted -s "$ESP" set 1 boot on
mkfs.fat -F32 -n EFI "$ESP"
MNT_LST+=("$ESP /boot$([ "$BIOSMODE" = uefi ]&&say /efi)")
infobox "Creating partition to install ExtOS"
if ! parted -s "$devdisk" mkpart primary ext4 101M 100%;then
msgbox "Failed to create partition on $devdisk"
continue
fi
rootfsdev=$(blk_p NAME "$devdisk"|tail -n 1)
parted -s "$devdisk" name 2 EXTOS
useencrypt(){
if ! cryptsetup luksFormat "$rootfsdev";then
msgbox "Failed to format $rootfsdev"
continue
fi
randname=$(randstr)
cryptsetup luksOpen "$rootfsdev" "$randname"
rootfsdev="/dev/mapper/$randname"
}
uselvm(){
if ! pvcreate "$rootfsdev";then
msgbox "Failed to create Physical Volume on $rootfsdev"
continue
fi
randname=$(randstr)
vgcreate "$randname" "$rootfsdev"
lvcreate -l 100%FREE -n EXTOS "$randname"
rootfsdev="/dev/mapper/$randname-EXTOS"
}
devsize=$(blk_d SIZE -b "$devdisk")
if((${devsize%MiB}>=8589934592));then
haslvm=
if((${devsize%MiB}>=34359738368));then
haslvm="\"LVM\" \"Use LVM multiple sub-partition on installation disk/partition (for over 32gb partitions and disks)\" \"LVM-on-Encrypt\" \"Use LVM multiple sub-partition on Encrypted installation disk/partition\""
fi
case "$(dbox --cancel-label No --menu "Do you want to use LVM and/or Encrypt the installation disk/partition?\n\nSelect the option in the list below:" 0 0 0 No "Do not use LVM or Encrypt the installation disk/partition" Encrypt "Encrypt the installation disk/partition" "$haslvm")" in
LVM)uselvm;;Encrypt)useencrypt;;LVM-on-Encrypt)useencrypt
uselvm;;esac
fi
mkfs.ext4 -F -L EXTOS "$rootfsdev"
MNT_LST+=("$rootfsdev /");;esac
diskconfirm=1
PRT_STAT="*"
break
done
}
listpvfree(){
pvfreelist=()
while IFS= read -r line;do
pvfreelist+=("\"$line\" \"$(pvs --noheadings -o pv_size,pv_free,pv_uuid "$line")\" off ")
done<<<"$(pvs --noheadings -o pv_name|grep -vf<(vgs --noheadings -o pv_name))"
}
advcd_lvmpvopts(){
while true;do
vg_grs=($(pvs --noheadings -o vg_name "$pvselect"))
case "$(dbox --cancel-label Back --menu "Physical Volume Infomation:\n\nPhysical Volume Name:$pvselect\nSize: $(pvs --noheadings -o pv_size "$pvselect")\nFree: $(pvs --noheadings -o pv_free "$pvselect")\nUUID: $(pvs --noheadings -o pv_uuid "$pvselect")\nVolume Group: $(append_comma "${vg_grs[*]}")\n\nSelect an option:" 0 80 0 Replace "Replace this Physical Volume with a new one" "Remove from VG" "Remove this Physical Volume from this Volume Group" Remove "Completely remove this Physical Volume")" in
Replace)ynwarn "Are you sure about replacin Physical Volume $pvselect with a new one?"
case $? in
1)continue;;3)break;;esac
while true;do
listpvfree
pvnew=$(dbox --cancel-label Back --menu "Select the new Physical Volume to replace this one\n" 0 80 0 "${pvfreelist[@]}")||break
vgchange -a n "$vgselect"&&pvmove "$pvselect" "$pvnew"&&vgchange -a y "$vgselect"||errbox "Could not replace Physical Volume $pvselect with $pvnew.\n\nPlease try again."
return
done;;"Remove from VG")ynwarn "Are you sure about removing Volume Group $vgselect?"
case $? in
1)continue;;3)break;;esac
vgchange -a n "$vgselect"&&pvmove "$pvselect"&&vgreduce "$vgselect" "$pvselect"&&vgchange -a y "$vgselect"||errbox "Could not remove Physical Volume $pvselect to the Volume Group $vgselect.\n\nPlease check the Volume Group and try again."
break;;Remove)ynwarn "Are you sure about removing Volume Group $vgselect?"
case $? in
1)continue;;3)break;;esac
vgchange -a n "$vgselect"&&pvmove "$pvselect"&&vgreduce "$vgselect" "$pvselect"&&pvremove "$pvselect"&&vgchange -a y "$vgselect"||errbox "Could not remove Volume Group $vgselect.\n\nPlease try again."
break;;*)break;;esac
done
}
advcd_lvmpv(){
while true;do
pvlist=()
for pv in "${pvofvg[@]}";do
pvinfo="$(pvs --noheadings -o pv_size,pv_free,pv_uuid "$pv"|awk '{for (i=1;i<NF;i++) printf "$i" " \t";print $NF}')"
pvlist+=("$pv" "$pvinfo")
done
pvselect=$(dbox --cancel-label Back --extra-button --extra-label Add --ok-label Select --menu "Select the Physical Volume to manage\n" 0 80 0 "${pvlist[@]}")
case $? in
0)advcd_lvmpvopts;;1)break;;3)listpvfree
pvselect=$(dbox --cancel-label Back --ok-label Select --checklist "Select the Physical Volume to add to this Volume Group\n" 0 80 0 "${pvfreelist[@]}")||continue
vgextend "$vgselect" "$pvselect"&&break
errbox "Could not add the Physical Volume to the Volume Group.\n\nPlease check the Volume Group and try again.";;esac
done
}
advcd_lvm(){
while true;do
vglist=()
while IFS= read -r line;do
vglist+=("$(awk '{print "$1"}'<<<"$line")" "$(awk '{for (i=2;i<NF;i++) printf "$i" " \t";print $NF}'<<<"$line")")
done<<<"$(vgs -o vg_name,vg_size,vg_free,vg_uuid --noheadings)"
vgselect=$(dbox --cancel-label Back --extra-button --extra-label Create --ok-label Select --help-button --help-label Done --menu "Select the Volume Group to manage\n" 0 80 0 "${vglist[@]}")
case $? in
0)while true;do
pvofvg=($(vgs --noheadings -o pv_name "$vgselect"))
lvofvg=($(vgs --noheadings -o lv_name "$vgselect"))
case "$(dbox --cancel-label Back --menu "Volume Group Infomation:\n\nVolume Group Name: $vgselect Size: $(vgs --noheadings -o vg_size "$vgselect")\nFree: $(vgs --noheadings -o vg_free "$vgselect")\nUUID: $(vgs --noheadings -o vg_uuid "$vgselect")\nPhysical Volumes: $(append_comma "${pvofvg[*]}")\nLogical Volumes: $(append_comma "${lvofvg[*]}")\n\nSelect an option:" 0 80 0 "Manage PV" "Manage Physical Volume attached to this Volume Group" "Manage LV" "Manage Logical Volume on this Volume Group" Rename "Rename this Volume Group" Remove "Remove this Volume Group")" in
"Manage PV")advcd_lvmpv;;"Manage LV")while true;do
lvlist=()
for lv in "${lvofvg[@]}";do
lvinfo="$(lvs --noheadings -o lv_size,lv_free,lv_uuid "$lv"|awk '{for (i=1;i<NF;i++) printf "$i" " \t";print $NF}')"
lvlist+=("$lv" "$lvinfo")
done
lvselect=$(dbox --cancel-label Back --extra-button --extra-label Remove --ok-label Rename --menu "Select the Physical Volume to manage\n" 0 80 0 "${lvlist[@]}")
case $? in
0)while true;do
newlvname=$(dbox --inputbox "Enter the new name for the logical partition" 0 0)||break
if [ -z "$newlvname" ];then
errbox "You didn't entered the new name!"
continue
fi
if lvs --noheadings -o lv_name|grep -q "$newlvname";then
errbox "The logical partition $newlvname already exists!"
continue
fi
lvrename "$lvselect" "$newlvname"
done;;3)ynwarn "Are you sure about removing Logical Volume $vgselect/$lvselect?"
case $? in
1)continue;;3)break;;esac
lvremove "$vgselect"/"$lvselect"
sleep 3;;esac
break
done;;Rename)while true;do
newvgname=$(dbox --inputbox "Enter the new name for the Volume Group" 0 0)||break
if [ -z "$newvgname" ];then
errbox "You didn't entered the new name!"
continue
fi
if vgs --noheadings -o vg_name|grep -q "$newvgname";then
errbox "The Volume Group $newvgname already exists!"
continue
fi
vgchange -a n "$vgselect"&&vgrename "$vgselect" "$newvgname"&&vgchange -a y "$newvgname"
sleep 3
break
done;;Remove)ynwarn "Are you sure about removing Volume Group $vgselect?"
case $? in
1)continue;;3)break;;esac
vgchange -an "$vgselect"&&vgremove "$vgselect"
sleep 3
break;;*)break;;esac
done;;1)return 1;;2)return;;3)listpvfree
pvselect=$(dbox --cancel-label Back --ok-label Create --checklist "Select the Physical Volumes to add to the Volume Group\n" 0 80 0 "${pvfreelist[@]}")||continue
newvgname=$(dbox --inputbox "Please enter the name of the new Volume Group" 0 0)||continue
if [ ! "$newvgname" ];then
errbox "You didn't entered the name of the new Volume Group!"
continue
fi
if vgs "$newvgname" >/dev/null 2>&1;then
errbox "The Volume Group $newvgname already exists!"
continue
fi
if vgcreate "$newvgname" "$pvselect";then
msgbox "Successfully created the Volume Group $newvgname!"
return
fi
errbox "Could not create the Volume Group $newvgname!";;esac
done
}
advcd_partopts(){
while true;do
xtraopt=
[[ "$devfstype" =~ crypt.* ]]&&xtraopt="\"Decrypt\" \"Mount Encrypted\""
[ "$devtype" = disk ]&&xtraopt="\"Manage\" \"Manage Volumes/Partitions\""
[ "$devtype" = lvm ]||[[ "$devfstype" =~ LVM.* ]]&&xtraopt="\"Manage LVM\" \"Manage LVM Physical Volumes, logical volumes, and Volume Groups\""
case "$(dbox --cancel-label Back --menu "${devtype^^} $devdisk\nType: $devtype\n$dorpa\nSize: $(blk_d SIZE "$devdisk")\n\nChoose an action:" 0 0 0 Mountpoint "Use $dorpb as " Format "Change filesystem of $dorpb" $xtraopt $lvmopt)" in
Mountpoint)while true;do
mntpt=$(dbox --cancel-label Back --menu "Choose mountpoint for $devtype $devdisk:\n\nNote: everything except '/' and '/boot' are optional" 0 0 0 "/" "This is where the base system will be installed" "/boot" "Needed for UEFI/LVM(bios/mbr)/encryption" "/boot/efi" "(UEFI) EFI System partition" "/home" "Userspace data will be saved here (not apply for Frugal Installation)" "/usr" "App data will be stored here (not apply for Frugal Installation)" "/etc" "App Configurations will be stored here (not apply for Frugal Installation)" "/root" "Userspace data for root/admin will be stored here (not apply for Frugal Installation)" "/var" "Stores app data, must be mounted as read-write (not apply for Frugal Installation)" "/data" "(Frugal only) Data partition, the same as '/var' partition in normal installation" "/overlay" "(Frugal only) Overlay partition, for storing overlay data" swap "Virtual memory partition")||break
ynwarn "All data on ${devtype^} $devdisk will be erased\n\nContinue?"
case $? in
1)continue;;3)break;;esac
if say "${MNT_LST[@]}"|grep -wq "$mntpt";then
ynwarn "The mountpoint $mntpt is already in use.\n\nContinue?"
case $? in
1)continue;;3)break;;esac
MNT_LST=("${MNT_LST[@]/$(say "${MNT_LST[@]}"|grep -w "$mntpt")/}")
fi
MNT_LST+=("$devdisk $mntpt")
if [ "$(say "${MNT_LST[@]}"|grep -w "/"|awk '{print "$2"}')" ];then
PRT_STAT="*"
else
PRT_STAT=
fi
return
done;;Format)while true;do
largedatafs="Filesystem for storing and managing large volume of data provided by"
dataonlyfs="for storing data or installing ExtOS Frugal only"
fsrv="for server use"
xtrafs=
[ "$(say "${MNT_LST[@]}"|grep "/boot"|awk '{print "$2"}')" ]&&xtrafs=(Encrypted "Encrypted filesystem, secure your data (/boot or /boot/efi is required)")
fsformat=$(dbox --cancel-label Back --menu "Please select the filesystem to be formated on $devdisk" 0 0 0 Ext2 "Standard Extended Filesystem for Linux version 2" Ext3 "Ext2 with journaling" Ext4 "Latest version of Extended Filesystem improved" BTRFS "$largedatafs BtrFS" XFS "High-performance filesystem, $fsrv" JFS "Journaled filesystem by IBM, $fsrv" ZFS "$largedatafs OpenZFS, $fsrv" FAT32 "Compatible, highly usable filesystem, $dataonlyfs" EXFAT "Extended FAT, $dataonlyfs" NTFS "Standard Windows filesystem, $dataonlyfs" F2FS "Fast filesystem used by Android data partition, $dataonlyfs" LVM "Logical Volume, for more partitions on 'msdos' partition table or group multiple drives (w or w/o RAID)" "${xtrafs[@]}" Swap "Virtual memory partition" Unformated "Empty/Wiped partition")||break
ynwarn "All data on ${devtype^} $devdisk will be erased\n\nContinue?"
case $? in
1)continue;;3)break;;esac
if [[ "$devfstype" =~ LVM.* ]];then
vgroup=$(pvs --noheadings -o vg_name "$devdisk"|awk '{print "$1"}')
pvmove "$devdisk"&&vgchange -an "$vgroup"&&vgreduce "$vgroup" "$devdisk"&&pvremove "$devdisk"&&vgchange -ay "$vgroup"||break
fi
case "$fsformat" in
Ext2|Ext3|Ext4)mkfs."${fsformat,,}" -F "$devdisk";;BTRFS|JFS|NTFS|F2FS|EXFAT)mkfs."${fsformat,,}" "$devdisk";;XFS)mkfs.xfs -f "$devdisk";;FAT32)mkfs.vfat -F 32 "$devdisk";;LVM)pvcreate "$devdisk";;ZFS)zfs_id=$(randstr)
zpool create -f "$zfs_id" "$devdisk";;Encrypted)while true;do
ecryptpass=$(dbox --cancel-label Back --inputbox "Please enter the password for the encrypted filesystem" 0 0)||break
if [ ! "$ecryptpass" ];then
errbox "Password cannot be empty"
continue
fi
ecryptpass2=$(dbox --cancel-label Back --inputbox "Please re-enter the password to confirm" 0 0)||break
if [ ! "$ecryptpass2" ];then
errbox "Password cannot be empty"
continue
fi
if [ "$ecryptpass" != "$ecryptpass2" ];then
errbox "Password does not match, please try again"
continue
fi
say "$ecryptpass\n$ecryptpass"|cryptsetup luksFormat "$devdisk"
say "$ecryptpass"|cryptsetup open "$devdisk" "$(randstr)"
done;;Swap)mkswap "$devdisk";;Unformated)wipefs -a "$devdisk";;esac||errbox "Error while formating the partition $devdisk as $fsformat, please try again"
return
done;;Decrypt)while true;do
cryptpass=$(dbox --inputbox --insecure "$devdisk appears to be an encrypted partition\nIt must be unlocked in order to continue\n\nPlease enter the encryption passphrase:" 0 0)||break
[ "$cryptpass" ]||errbox "You didn't entered the encryption passphrase!"
say "$cryptpass"|cryptsetup open "$devdisk" "$(randstr)"&&return
errbox "Could not unlock the partition.\n\nPlease check the passphrase and try again."
done;;Manage)cfdisk "$devdisk";;"Manage LVM")advcd_lvm&&return;;*)break;;esac
done
}
advcd_diskman(){
mount_check
while true;do
disklst
if [ ! "${devs[*]}" ];then
msgbox "No device is available to install"
return 1
fi
devdisk=$(dbox --cancel-label Back --ok-label Select --extra-button --extra-label Next --menu "Select the disk/partition for ExtOS to be installed on. Note that the disk/partition you select will be erased, but not until you have confirmed the changes.\n\nSelect the disk in the list below:" 0 80 0 "${devs[@]}")
case $? in
0)devtype=$(blk_d TYPE "$devdisk")
devfstype=$(blk_d FSTYPE "$devdisk")
if [ "$devtype" = disk ];then
dorpa="Partition table: $(fdisk -l "$devdisk"|grep Disklabel|awk '{print "$3"}')"
dorpb="entire disk"
else
dorpa="Filesystem: $devfstype"
dorpb="this partition"
fi
advcd_partopts
continue;;3)diskconfirm=1;;esac
break
done
}
ossel(){
title=$TITLE
while true;do
os_base=$(dbox --cancel-label "Exit to menu" --menu "Choose based distro" 0 0 0 Arch "Arch Linux based full installation" Debian "Debian based full installation" Frugal "Minimal frugal installation" "Frugal Extended" "ExtCore full installation")
if [ $? != 0 ];then
menusel
return
fi
if [ "$is64" = 1 ]&&yesnobox "Your CPU supports 64-bit architecture, would you like to install ExtOS 64bit?";then
arct=amd64
else
arct=i386 # Uses i686 instead
fi
picustom="\"custom\" \"Customize your own preset\" off"
case "$os_base" in
Arch)os_base=arch;;Debian)os_base=deb;;"Frugal Extended")os_base=sfsrw;;Frugal)os_base=sfs
picustom=;;esac
initsel
[ "$OS_STAT" ]&&return
done
}
initsel(){
while true;do
initype=$(dbox --cancel-label Back --radiolist "Use arrow keys and Space to select which init system you would prefered\n\nComparision: https://wiki.gentoo.org/wiki/Comparison_of_init_systems" 0 0 0 SystemD "Standard init system, provides more than just an init system" on OpenRC "SysVinit based, suitable for minimal installation" off runit "A daemontools-inspired process supervision suite" off)||break
case "$initype" in
SystemD)initype=sysd;;OpenRC)initype=oprc;;runit)initype=rnit;;esac
libcsel
[ "$OS_STAT" ]&&return
done
}
libcsel(){
while true;do
libctype=$(dbox --cancel-label Back --radiolist "Use arrow keys and Space to select which libc you would prefered\n\nComparision: https://wiki.gentoo.org/wiki/Comparison_of_libc" 0 0 0 glibc "Standard libc, supports most of the modern linux kernel" on musl "Minimal libc, supports only the bare minimum for the kernel" off)||break
pisel
[ "$OS_STAT" ]&&return
done
}
pisel(){
while true;do
piscript=$(dbox --ok-label Next --cancel-label Back --extra-button --extra-label Skip --checklist "Choose one of the presets below, or do it later\nUse arrows key and space" 0 0 0 gaming "Cross-play suite for gamers" off office "Suit for office work or content creation, with many useful softwares" off design "Suit for graphic/art/architecture design" off devel "Developing enviroment for coders/developers" off server "Tools and utilities for a mini host server" off security "Tools and softwares for white-hat hacking/penetration testing" off "$picustom")
case $? in
0)for f in $piscript;do
[ -f "preset/$f/$arct/pkglist-$os_base" ]&&cat "preset/$f/$arct/pkglist-$os_base">>pkglist
done
sort -u pkglist -o pkglist
if [ "$piscript" = "*custom*" ];then
pkglist=$(wraptt "Customize your own preset" dbox --ok-label Save --cancel-label Continue --editbox pkglist 0 0)&&saybr "$pkglist" >pkglist
fi
OS_STAT="*";;1)break;;3)OS_STAT="*";;esac
[ "$OS_STAT" ]&&return
done
}
mount_part(){
mount -m "$1" "/mnt$2"
}
start_install(){
if [ ! "$PRT_STAT" ];then
wraptt "Partition the harddrive" msgbox "You haven't selected the root partition yet."
diskchoose
menusel
return
fi
if [ ! "$OS_STAT" ];then
wraptt "OS selection" msgbox "You haven't selected the OS yet."
ossel
menusel
return
fi
if ! wraptt Confirmation yesnobox "You have selected these:\n\n Base: $os_base\n Init system: $initype\n Libc: $libctype\n Presets: $piscript\n Partition table: \n $(for p in "${MNT_LST[@]}";do saybr "$p";done)\n \n Do you want to continue?";then
ossel
return
fi
for p in "${MNT_LST[@]}";do
mount_part "${p% *}" "${p# *}"&&continue
errbox "Failed to mount the root partition!"
umount /mnt/*
menusel
return
done
if ! curl -L -o /mnt/rootfs.sfs "$URL/root-$os_base-$initype-$libctype-$arct.sfs"||! wget -O /mnt/rootfs.sfs "$URL/root-$os_base-$initype-$libctype-$arct.sfs";then
errbox "Failed to download the rootfs image!"
menusel
return
fi
for pi in "${piscript[@]}";do
[ "$pi" = custom ]&&continue
if ! curl -L -o "/mnt/pi/$pi.sfs" "$URL/pi/$pi.sfs"&&! wget -O "/mnt/pi/$pi.sfs" "$URL/pi/$pi.sfs";then
errbox "Failed to download the $pi image!"
menusel
return
fi
done
if [ "$os_base" != sfs ];then
for i in $(printf '%s\n' "${MNT_LST[@]}"|grep -Evw "/|/data|/overlay|swap");do
mount_part "$i"&&continue
errbox "Failed to mount the $i partition!"
menusel
return
done
if ! unsquashfs -f -d /mnt /mnt/rootfs.sfs;then
errbox "Failed to unpack the rootfs image!"
menusel
return
fi
if ! echo "${piscript[@]}"|grep -q custom;then
for pi in "${piscript[@]}";do
unsquashfs -f -d "/mnt /mnt/pi/$pi.sfs"&&continue
errbox "Failed to unpack the $pi image!"
menusel
return
done
else
for pi in "${piscript[@]}";do
if [ "$pi" = custom ];then
continue
fi
cp -r "preset/$pi/$arct"/* /mnt
done
if [ "$os_base" = deb ];then
chroot /mnt apt-get update
chroot /mnt xargs apt-get -y install<pkglist
elif [ "$os_base" = arch ];then
chroot /mnt pacman -S -<pkglist
fi
fi
else
if ! curl -L -o /mnt/data.img "$URL/data-$arct.img"&&! wget -O /mnt/data.img "$URL/data-$arct.img";then
errbox "Failed to download the data.img image!"
menusel
return
fi
external_data=$(printf '%s\n' "${MNT_LST[@]}"|grep -w "/data")
if [ -n "$external_data" ];then
external_data_dev=$(echo "$external_data"|awk '{print "$1"}')
dd if=/mnt/data.img of="$external_data_dev" bs=4M
sed -i "s/data=\/cdrom\/data.img/data=$external_data_dev/g" /mnt/boot/grub/grub.cfg
fi
cp -r "preset/0-global/$arct/boot" /mnt/boot
if wraptt Overlay yesnobox "Do you want to enable overlay?";then
external_overlay=$(printf '%s\n' "${MNT_LST[@]}"|grep -w "/overlay")
if [ -n "$external_overlay" ];then
overlay_dev=$(echo "$external_overlay"|awk '{print "$1"}')
else
overlay_dev=/mnt/overlay.img
dd if=/dev/zero of="$overlay_dev" bs=1M count=$(($(df -m /mnt|tail -n 1|awk '{print "$2"}') - $(du -m /mnt/root.sfs|awk '{print "$1"}') - $(du -m /mnt/data.img|awk '{print "$1"}') - $(du -m /mnt/pi|awk '{print "$1"}')))
fi
mkfs.ext4 -L overlay "$overlay_dev"
sed -i "s/overlay=tmpfs/overlay=$overlay_dev/" /mnt/boot/grub/grub.cfg
sed -i "s/overlayfstype=tmpfs overlayflags=nodev,nosuid//" /mnt/boot/grub/grub.cfg
else
sed -i "s/overlay=tmpfs overlayfstype=tmpfs overlayflags=nodev,nosuid//" /mnt/boot/grub/grub.cfg
dd if=/dev/zero of=/mnt/data.img bs=1M count=$(($(df -m /mnt|tail -n 1|awk '{print "$2"}') - $(du -m /mnt/root.sfs|awk '{print "$1"}') - $(du -m /mnt/pi|awk '{print "$1"}')))
fi
fi
if [ "$useswp" = 1 ];then
dd if=/dev/zero of=/mnt/swap bs=1M count=1024
mkswap /mnt/swap
fi
INS_STAT="*"
wraptt Finished dbox --extra-button --extra-label Other --yesno "Do you want to reboot?"
case $? in
0)reboot;;1)menusel;;esac
}
poweropts(){
title="Power options"
case "$(dbox --cancel-label Back --menu "Choose option to continue:" 0 0 0 "Reboot " "Restart the machine and also the installer" "Sleep " "Suspend the machine and save current state to RAM/swap" Hibernate "Hibernate the machine and save current state to disk/RAMdisk" "Shutdown " "Exit the installer and power off the machine")" in
"Reboot ")reboot;;"Sleep ")$INIT_SYSTEM suspend;;Hibernate)$INIT_SYSTEM hibernate;;"Shutdown ")poweroff;;esac
}
menusel(){
title="Main menu"
while true;do
case "$(dbox --nocancel --menu "Select an option below using the UP/DOWN, PLUS(+) or MINUS(-) keys and SPACE or ENTER.\nIf there is an asterisk at the end of the entry means it's configured" 0 0 0 "NETWORK " "Manually config the network $NET_STAT" "KEYMAP " "Set the keyboard layout $KEY_STAT" "LOCALE " "Set the system locale $LOC_STAT" "TIMEZONE " "Set the system time zone $TZC_STAT" "CREATE USER" "Create your user account $USR_STAT" "PARTITION " "Partition the installation drive $PRT_STAT" "OS " "Select the operating system $OS_STAT" "INSTALL " "Install ExtOS Linux respin $INS_STAT" "POWER " "Power options" "EXIT " "Exit the installer")" in
"NETWORK ")NET_MSG="\e[0mFrom here you'll configure the network manually"&&netcheck;;"KEYMAP ")keymapc;;"LOCALE ")localec;;"TIMEZONE ")localtz;;"CREATE USER")usrname;;"PARTITION ")diskchoose;;"OS ")ossel;;"INSTALL ")start_install;;"POWER ")poweropts;;*)die;;esac
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
start_install
poweropts
}
yesnobox "This is ExtOS linux respin v0.1\nMade by Shadichy\n\nStart installation process?"||die
main "$@"
