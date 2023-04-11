#!/bin/bash

ossel() {
	title=$TITLE
	while true; do
		os_base=$(dbox --cancel-label "Exit to menu" --menu "Choose based distro" 0 0 0 \
			"Arch" "Arch Linux based full installation" \
			"Debian" "Debian based full installation" \
			"Frugal" "Minimal frugal installation" \
			"Frugal Extended" "ExtCore full installation" )
		if [ $? != 0 ]; then
			menusel
			return
		fi
		if [ "$is64" = 1 ] && yesnobox "Your CPU supports 64-bit architecture, would you like to install ExtOS 64bit?"; then
			arct="amd64"
		else
			arct="i386" # Uses i686 instead
		fi
		picustom="\"custom\" \"Customize your own preset\" off"
		case "$os_base" in
		"Arch") os_base="arch" ;;
		"Debian") os_base="deb" ;;
		"Frugal Extended") os_base="sfsrw" ;;
		"Frugal")
			os_base="sfs"
			picustom=""
			;;
		esac
		initsel
		[ "$OS_STAT" ] && return
	done
}

initsel() {
	while true; do
		initype=$(dbox --cancel-label "Back" --radiolist "Use arrow keys and Space to select which init system you would prefered\n\nComparision: https://wiki.gentoo.org/wiki/Comparison_of_init_systems" 0 0 0 \
			"SystemD" "Standard init system, provides more than just an init system" on "OpenRC" "SysVinit based, suitable for minimal installation" off "runit" "A daemontools-inspired process supervision suite" off) || break
		case "$initype" in
		"SystemD") initype="sysd" ;;
		"OpenRC") initype="oprc" ;;
		"runit") initype="rnit" ;;
		esac
		libcsel
		[ "$OS_STAT" ] && return
	done
}

libcsel() {
	while true; do
		libctype=$(dbox --cancel-label "Back" --radiolist "Use arrow keys and Space to select which libc you would prefered\n\nComparision: https://wiki.gentoo.org/wiki/Comparison_of_libc" 0 0 0 \
			"glibc" "Standard libc, supports most of the modern linux kernel" on "musl" "Minimal libc, supports only the bare minimum for the kernel" off) || break
		pisel
		[ "$OS_STAT" ] && return
	done
}

pisel() {
	while true; do
		piscript=$(dbox --ok-label "Next" --cancel-label "Back" --extra-button --extra-label "Skip" --checklist "Choose one of the presets below, or do it later\nUse arrows key and space" 0 0 0 \
			"gaming" "Cross-play suite for gamers" off \
			"office" "Suit for office work or content creation, with many useful softwares" off \
			"design" "Suit for graphic/art/architecture design" off \
			"devel" "Developing enviroment for coders/developers" off \
			"server" "Tools and utilities for a mini host server" off \
			"security" "Tools and softwares for white-hat hacking/penetration testing" off \
			"$picustom")
		case $? in
		0)
			for f in $piscript; do
				[ -f "preset/$f/$arct/pkglist-$os_base" ] && cat "preset/$f/$arct/pkglist-$os_base" >>pkglist
			done
			sort -u pkglist -o pkglist
			if [ "$piscript" == "*custom*" ]; then
				pkglist=$(dialog --backtitle "$BACKTITLE" --title "Customize your own preset" --stdout --ok-label "Save" --cancel-label "Continue" --editbox "pkglist" 0 0) && saybr "$pkglist" >pkglist
				
			fi
			OS_STAT="*"
			;;
		1) break ;;
		3) OS_STAT="*" ;;
		esac
		[ "$OS_STAT" ] && return
	done
}
