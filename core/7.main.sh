#!/bin/bash

poweropts() {
  case "$(dialog --backtitle "$BACKTITLE" --title "Power options" --cancel-label "Back" --stdout --menu "Choose option to continue:" 0 0 0 \
    "Reboot   " "Restart the machine and also the installer" \
    "Sleep    " "Suspend the machine and save current state to RAM/swap" \
    "Hibernate" "Hibernate the machine and save current state to disk/RAMdisk" \
    "Shutdown " "Exit the installer and power off the  machine")" in
  "Reboot   ") reboot ;;
  "Sleep    ") $INIT_SYSTEM suspend ;;
  "Hibernate") $INIT_SYSTEM hibernate ;;
  "Shutdown ") poweroff ;;
  esac
}

menusel() {
  while true; do
    case "$(dialog --backtitle "$BACKTITLE" --title "Main Menu" --nocancel --stdout \
      --menu "Select an option below using the UP/DOWN, PLUS(+) or MINUS(-) keys and SPACE or ENTER.\nIf there is an asterisk at the end of the entry means it's configured" 0 0 0 \
      "NETWORK    " "Manually config the network           $NET_STAT" \
      "KEYMAP     " "Set the keyboard layout               $KEY_STAT" \
      "LOCALE     " "Set the system locale                 $LOC_STAT" \
      "TIMEZONE   " "Set the system time zone              $TZC_STAT" \
      "CREATE USER" "Create your user account              $USR_STAT" \
      "PARTITION  " "Partition the installation drive      $PRT_STAT" \
      "OS         " "Select the operating system           $OS_STAT" \
      "INSTALL    " "Install ExtOS Linux respin            $INS_STAT" \
      "POWER      " "Power options" \
      "EXIT       " "Exit the installer")" in
    "NETWORK    ") NET_MSG="\e[0mFrom here you'll configure the network manually" && netcheck ;;
    "KEYMAP     ") keymapc ;;
    "LOCALE     ") localec ;;
    "TIMEZONE   ") localtz ;;
    "CREATE USER") usrname ;;
    "PARTITION  ") diskchoose ;;
    "OS         ") ossel ;;
    "INSTALL    ") start_install ;;
    "POWER      ") poweropts ;;
    *) reset; saybr "Run ./install.sh to restart the installer."; exit ;;
    esac
  done
}

main() {
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

if dialog --backtitle "$BACKTITLE" --title "$TITLE" --yesno "This is ExtOS linux respin v0.1\nMade by Shadichy\n\nStart installation process?" 0 0; then
  # menusel
  main "$@"
  exit 0
fi
printf "Run ./install.sh to restart the installer\n"
