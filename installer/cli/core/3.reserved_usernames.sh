#!/bin/bash

# List of reserved usernames used to avoid any conflict when creating a user.
# https://salsa.debian.org/installer-team/user-setup/raw/master/reserved-usernames

reserved_usernames=(

# Static users from base-passwd/passwd.master (3.5.41).
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

# Other static groups from base-passwd/group.master (3.5.41).
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

# Reserved usernames listed in base-passwd/README (3.5.41).
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

# Ubuntu creates the admin group and adds the first user to it in order to
# grant them sudo privileges.
admin

# Other miscellaneous system users/groups created by common packages. While
# it's useful to add things here that people might run into, it's not
# absolutely critical; the worst that will happen is that the installation
# will fail at some later point.
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
