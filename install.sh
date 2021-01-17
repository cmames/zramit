#!/bin/sh
#[ "$(id -u)" -eq '0' ] || { echo "This script requires root." && exit 1; }

case "$(readlink /proc/$$/exe)" in */bash) set -euo pipefail ;; *) set -eu ;; esac

# ensure a predictable environment
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
\unalias -a

# installer main body:
_main() {
  # ensure $1 exists so 'set -u' doesn't error out
  { [ "$#" -eq "0" ] && set -- ""; } > /dev/null 2>&1

  case "$1" in
    "--uninstall")
      # uninstall, requires root
      assert_root
      _uninstall
      ;;
    "--install" | "")
      # install dpkg hooks, requires root
      assert_root
      _install "$@"
      ;;
    *)
      # unknown flags, print usage and exit
      _usage
      ;;
  esac
  exit 0
}

_install() {
  set +e
  iswhiptail=$(command -v whiptail)
  set -e
  if ! [ -z $iswhiptail ];then
    TERM=ansi whiptail --title "zramit" --infobox "Prepare install\n\nplease wait ..." 14 58
  else echo "Prepare install"
  fi

  configdiff=''
  newconfig=''
  if systemctl -q is-active zramit.service; then
    if ! [ -z $iswhiptail ];then
      sleep 1
      TERM=ansi whiptail --title "zramit" --infobox "Stopping zramit service" 14 58
    else echo "Stopping zramit service"
    fi
    systemctl stop zramit.service
  fi

  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Installing script and service...\n  [-] installing script\n  [ ] installing hibernate script\n  [ ] installing service\n  [ ] installing config file" 14 58 
  else
      echo "Installing script and service ..."
      echo "  ├ installing script"
  fi
  install -o root zramit.sh /usr/local/sbin/zramit.sh
  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Installing script and service...\n  [X] installing script\n  [-] installing hibernate script\n  [ ] installing service\n  [ ] installing config file" 14 58 
  else
    echo "  ├ installing hibernate script"
  fi
  install -o root zramit-hibernate.sh /lib/systemd/system-sleep/zramit-hibernate.sh
  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Installing script and service...\n  [X] installing script\n  [X] installing hibernate script\n  [-] installing service\n  [ ] installing config file" 14 58 
  else
    echo "  ├ installing service"
  fi
  install -o root -m 0644 service/zramit.service /etc/systemd/system/zramit.service
  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Installing script and service...\n  [X] installing script\n  [X] installing hibernate script\n  [X] installing service\n  [-] installing config file" 14 58 
  else
    echo "  └ installing config file"
  fi

  if [ -f /etc/default/zramit.conf ]; then
    {
      set +e
      grep "_zram" /etc/default/zramit.conf > oldconf
      grep "_zram" service/zramit.config > newconf
      configdiff=$(diff -u --suppress-common-line oldconf newconf | grep "^[-+]" | sed -e "s/oldconf.*/installed config/g" -e "s/newconf.*/package config/g" -e "s/^-\([^-]\)/--- \1/g" -e "s/^+\([^+]\)/+++ \1/g")
      rm oldconf
      rm newconf
      set -e
    } > /dev/null 2>&1
    if [ -n "$configdiff" ]; then
      yn=''
      if ! [ -z $iswhiptail ];then
        sleep 1
        if (TERM=ansi whiptail --title "zramit" --yesno "Installed configuration differs from packaged version\n\n would you want to see differences?" 14 58);then
          echo "$configdiff">text_box
          sed -i -e "s/^</installed </g" text_box
          sed -i -e "s/^>/package >/g" text_box
          TERM=ansi whiptail --title "zramit" --textbox text_box 14 78
          rm text_box
        fi
        if (TERM=ansi whiptail --title "zramit" --yesno "Installed configuration differs from packaged version\n\n install packaged config?" 14 58);then
          install -o root -m 0644 --backup --suffix=".oldconfig" service/zramit.config /etc/default/zramit.conf
          newconfig='y'
          TERM=ansi whiptail --title "zramit" --msgbox "Original config backed up as /etc/default/zramit.oldconfig" 14 58
        fi
      else
        echo "Installed configuration differs from packaged version."
        echo
        echo "Install packaged config? Original will be backed up as /etc/default/zramit.oldconfig"
        while true; do
          echo "(y)Install packaged config / (n)Keep current / (s)Show diff"
          printf "[y/n/s]: "
          read yn
          case "$yn" in
            [Yy]*)
              echo "Installing packaged config ..."
              install -o root -m 0644 --backup --suffix=".oldconfig" service/zramit.config /etc/default/zramit.conf
              newconfig='y'
              break
              ;;
            [Nn]*) break ;;
            [Ss]*) echo "$configdiff\n\n" ;;
          esac
        done
      fi
    fi
  else
    install -o root -m 0644 -b service/zramit.config /etc/default/zramit.conf
  fi
  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Installing script and service...\n  [X] installing script\n  [X] installing hibernate script\n  [X] installing service\n  [X] installing config file" 14 58 
  fi

  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Reloading systemd unit files and enabling boot-time service ..." 14 58 
  else
    echo "Reloading systemd unit files and enabling boot-time service ..."
  fi
  systemctl daemon-reload
  systemctl enable zramit.service

  if ! [ -z $iswhiptail ];then
    TERM=ansi whiptail --title "zramit" --infobox "Starting zram  service ..." 14 58 
  else
    echo "Starting zramit service ..."
  fi
  systemctl start zramit.service
  zramdetail=$(zramctl)

  if ! [ -z $iswhiptail ];then
    echo "zram service installed successfully!\n\n$zramdetail">text_box
    TERM=ansi whiptail --title "zramit" --textbox text_box 14 78
    rm text_box
  else
    echo
    echo "zramit service installed successfully!"
    echo
    echo "$zramdetail"
  fi
}

_uninstall() {
  set +e
  iswhiptail=$(command -v whiptail)
  set -e
  if ! [ -z $iswhiptail ];then
    TERM=ansi whiptail --title "zramit" --infobox "Stopping zramit service" 14 58
  else echo "Stopping zramit service"
  fi
  if systemctl -q is-active zramit.service; then
    systemctl stop zramit.service
  fi

  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Uninstalling script and service...\n  [-] remove script\n  [ ] remove hibernate script\n  [ ] remove service\n  [ ] remove config file" 14 58 
  else
      echo "Unnstalling script and service ..."
      echo "  ├ remove script"
  fi
  if [ -f /usr/local/sbin/zramit.sh ]; then
    rm -f /usr/local/sbin/zramit.sh
  fi
  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Uninstalling script and service...\n  [X] remove script\n  [-] remove hibernate script\n  [ ] remove service\n  [ ] remove config file" 14 58 
  else
    echo "  ├ remove hibernate script"
  fi
  if [ -f /lib/systemd/system-slepp/zramit-hibernate.sh ]; then
    rm -f /lib/systemd/system-sleep/zramit-hibernate.sh
  fi
  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Uninstalling script and service...\n  [X] remove script\n  [X] remove hibernate script\n  [-] remove service\n  [ ] remove config file" 14 58 
  else
    echo "  ├ remove service"
  fi
  if [ -f /etc/systemd/system/zramit.service ]; then
    systemctl disable zramit.service || true
    rm -f /etc/systemd/system/zramit.service
  fi
  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Uninstalling script and service...\n  [X] remove script\n  [X] remove hibernate script\n  [X] remove service\n  [-] remove config file" 14 58 
  else
    echo "  └ remove config file"
  fi
  if [ -f /etc/default/zramit.conf ]; then
    rm -f /etc/default/zramit.conf
  fi

  if ! [ -z $iswhiptail ];then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Reloading systemd unit files" 14 58 
  else
    echo "Reloading systemd unit files"
  fi
  systemctl daemon-reload

  if ! [ -z $iswhiptail ];then
    TERM=ansi whiptail --title "zramit" --msgbox "zramit uninstalled" 14 78
  else
    echo
    echo "zramit service uninstalled"
    echo
  fi
}

assert_root() { [ "$(id -u)" -eq '0' ] || { echo "This action requires root." && exit 1; }; }
_usage() { echo "Usage: $(basename "$0") (--install|--uninstall)"; }

_main "$@"
