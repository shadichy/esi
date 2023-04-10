#!/bin/bash



mount_part() {
  mount -m "$1" "/mnt$2"
}

start_install() {
  if [ ! "$PRT_STAT" ]; then
    dialog --backtitle "$BACKTITLE" --title "Partition the harddrive" --msgbox "You haven't selected the root partition yet." 0 0
    diskchoose
    menusel
    return
  fi

  if [ ! "$OS_STAT" ]; then
    dialog --backtitle "$BACKTITLE" --title "OS selection" --msgbox "You haven't selected the OS yet." 0 0
    ossel
    menusel
    return
  fi

  if ! dialog --backtitle "$BACKTITLE" --title "Confirmation" --yesno "You have selected these:\n\n\
    Base: $os_base\n\
    Init system: $initype\n\
    Libc: $libctype\n\
    Presets: $piscript\n\

    Partition table: \n\
    $(for p in "${MNT_LST[@]}"; do saybr "$p"; done)\n\
    \n\
    Do you want to continue?" 0 0; then
    ossel
    return
  fi

  for p in "${MNT_LST[@]}"; do
    mount_part "${p% *}" "${p# *}" && continue
    dialog --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "ERROR: Failed to mount the root partition!"
    umount /mnt/*
    menusel
    return
  done

  if ! curl -L -o /mnt/rootfs.sfs "$sfs_srv/root-$os_base-$initype-$libctype-$arct.sfs" || ! wget -O /mnt/rootfs.sfs "$sfs_srv/root-$os_base-$initype-$libctype-$arct.sfs"; then
    dialog --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "ERROR: Failed to download the rootfs image!"
    menusel
    return
  fi

  for pi in "${piscript[@]}"; do
    [ "$pi" = "custom" ] && continue
    if ! curl -L -o "/mnt/pi/$pi.sfs" "$sfs_srv/pi/$pi.sfs" || ! wget -O "/mnt/pi/$pi.sfs" "$sfs_srv/pi/$pi.sfs"; then
      dialog --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "ERROR: Failed to download the $pi image!"
      menusel
      return
    fi
  done
  
  if [ "$os_base" != "sfs" ]; then
    for i in $(printf '%s\n' "${MNT_LST[@]}" | grep -Evw "/|/data|/overlay|swap"); do
      mount_part "$i"
      if [ $? != 0 ]; then
        dialog --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "ERROR: Failed to mount the $i partition!"
        menusel
        return
      fi
    done
    if ! unsquashfs -f -d /mnt /mnt/rootfs.sfs; then
      dialog --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "ERROR: Failed to unpack the rootfs image!"
      menusel
      return
    fi
    if ! echo "${piscript[@]}" | grep -q "custom"; then
      for pi in "${piscript[@]}"; do
        if ! unsquashfs -f -d "/mnt /mnt/pi/$pi.sfs"; then
          dialog --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "ERROR: Failed to unpack the $pi image!"
          menusel
          return
        fi
      done
    else
      for pi in "${piscript[@]}"; do
        if [ "$pi" = "custom" ]; then
          continue
        fi
        cp -r "preset/$pi/$arct"/* /mnt
      done
      if [ "$os_base" == "deb" ]; then
        chroot /mnt apt-get update
        chroot /mnt xargs apt-get -y install <pkglist
      elif [ "$os_base" == "arch" ]; then
        chroot /mnt pacman -S - <pkglist
      fi
    fi
  else
    if ! curl -L -o /mnt/data.img "$sfs_srv/data-$arct.img" || ! wget -O /mnt/data.img "$sfs_srv/data-$arct.img"; then
      dialog --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "ERROR: Failed to download the data.img image!"
      menusel
      return
    fi
    external_data=$(printf '%s\n' "${MNT_LST[@]}" | grep -w "/data")
    if [ -n "$external_data" ]; then
      external_data_dev=$(echo "$external_data" | awk '{print "$1"}')
      dd if=/mnt/data.img of="$external_data_dev" bs=4M
      sed -i "s/data=\/cdrom\/data.img/data=$external_data_dev/g" /mnt/boot/grub/grub.cfg
    fi
    cp -r "preset/0-global/$arct/boot" /mnt/boot
    if dialog --backtitle "$BACKTITLE" --title "Overlay" --yesno "Do you want to enable overlay?"; then
      external_overlay=$(printf '%s\n' "${MNT_LST[@]}" | grep -w "/overlay")
      if [ -n "$external_overlay" ]; then
        overlay_dev=$(echo "$external_overlay" | awk '{print "$1"}')
      else
        overlay_dev=/mnt/overlay.img
        dd if=/dev/zero of="$overlay_dev" bs=1M count=$(($(df -m /mnt | tail -n 1 | awk '{print "$2"}') - $(du -m /mnt/root.sfs | awk '{print "$1"}') - $(du -m /mnt/data.img | awk '{print "$1"}') - $(du -m /mnt/pi | awk '{print "$1"}')))
      fi
      mkfs.ext4 -L overlay "$overlay_dev"
      sed -i "s/overlay=tmpfs/overlay=$overlay_dev/" /mnt/boot/grub/grub.cfg
      sed -i "s/overlayfstype=tmpfs overlayflags=nodev,nosuid//" /mnt/boot/grub/grub.cfg
    else
      sed -i "s/overlay=tmpfs overlayfstype=tmpfs overlayflags=nodev,nosuid//" /mnt/boot/grub/grub.cfg
      dd if=/dev/zero of=/mnt/data.img bs=1M count=$(($(df -m /mnt | tail -n 1 | awk '{print "$2"}') - $(du -m /mnt/root.sfs | awk '{print "$1"}') - $(du -m /mnt/pi | awk '{print "$1"}')))
    fi
  fi
  if [ "$useswp" = 1 ]; then
    dd if=/dev/zero of=/mnt/swap bs=1M count=1024
    mkswap /mnt/swap
  fi
  # is it finished?
  # no u fcking idiot, there are lots of things to do here
  INS_STAT="*"
  dialog --backtitle "$BACKTITLE" --title "Finished" --extra-button --extra-label "Other" --yesno "Do you want to reboot?"
  case $? in
  0) reboot ;;
  1) menusel ;;
  esac
}
