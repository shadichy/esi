#!/bin/bash

netcheck() {
	while true; do
		if curl -I http://archlinux.org || wget -q --spider http://archlinux.org || nc -zw1 archlinux.org 80; then
			CONNECTED=2
			OFFLINE=0
			NET_STAT="*"
			return
		fi
		[ "$OFFLINE" = 1 ] && yesnobox "Continue without network?" && CONNECTED=1
		NET_MSG="\e[1;31mYou'll need to configure the network before installing or else some packages will be broken"

		[ "$CONNECTED" = 0 ] || break

		clear
		saybr "$NET_MSG"
		saybr ""
		saybr ""
		saybr "\e[1;32mQuick guide:"
		saybr ""
		saybr "\e[1;33m  (For more 'space': Press Ctrl + Alt + F2 switching to TTY2 (Ctrl + Alt + F1 to get back) or open a new terminal window/tab/session(tmux))\e[1;36m"
		saybr ""
		saybr "\tRun command 'ip link' to check enabled network interfaces"
		saybr "\tRun command 'rfkill list all' to list blocked network card and 'rfkill unblock all' to unblock all Soft-blocked network card"
		saybr "\tRun command 'iwctl' or 'wpa_cli' to configure wireless connection"
		saybr "\tRun command 'mmcli' to configure mobile network"
		saybr ""
		saybr "\e[1;35m  Finally, 'ping' some websites to check if it works or not"
		saybr ""
		saybr ""
		saybr "\e[0mType 'exit' after you have done all the jobs"
		saybr ""
		$SHELL
		OFFLINE=1
	done
}

dircheck() {
	find ./ -type d -iname "esi" -print -quit -exec cd {} \; ||
		[ "$CONNECTED" = 2 ] &&
		git clone https://github.com/shadichy/esi.git &&
		cd ./esi &&
		WORKDIR=$(pwd) || die "Network unavailable, can't fetch installation needs"
}
