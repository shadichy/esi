#!/bin/bash

netcheck() {
    if [ "$CONNECTED" = 0 ]; then
        clear
        saybr "$NET_MSG"
        saybr ""
        saybr ""
        saybr "\e[1;32mQuick guide:"
        saybr ""
        saybr "\e[1;33m  (For more 'space': Press Ctrl + Alt + F2 switching to TTY2 (Ctrl + Alt + F1 to get back) or open a new terminal window/tab/session(tmux))\e[1;36m"
        saybr ""
        saybr "    Run command 'ip link' to check enabled network interfaces"
        saybr "    Run command 'rfkill list all' to list blocked network card and 'rfkill unblock all' to unblock all Soft-blocked network card"
        saybr "    Run command 'iwctl' or 'wpa_cli' to configure wireless connection"
        saybr "    Run command 'mmcli' to configure mobile network"
        saybr ""
        saybr "\e[1;35m  Finally, 'ping' some websites to check if it works or not"
        saybr ""
        saybr ""
        saybr "\e[0mType 'exit' after you have done all the jobs"
        saybr ""
        $SHELL
        OFFLINE=1
        init
    fi
}
