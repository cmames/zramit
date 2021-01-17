#!/bin/sh

[ "$(id -u)" -eq '0' ] || { echo "This action requires root.\n use : sudo $0 $*" && exit 1; }

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
      # uninstall
      _uninstall
      ;;
    "--install" | "")
      # install
      _install "$@"
      ;;
    "--config")
      # config
      _config
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
    if ! [ -z $iswhiptail ];then
      if (TERM=ansi whiptail --title "zramit" --yesno "Would you want to use the config assistant?" 14 58);then
        _config
      fi
    else
      echo "Would you want to use the config assistant?"
      printf "[y/n]: "
      read yn
      case "$yn" in
        [Yy]*)
          _config
          break
          ;;
        *) break ;;
      esac
    fi
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
    TERM=ansi whiptail --clear --title "zramit" --textbox text_box 14 78
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
    TERM=ansi whiptail --clear --title "zramit" --msgbox "zramit uninstalled" 14 78
  else
    echo
    echo "zramit service uninstalled"
    echo
  fi
}

_config() {
  set +e
  iswhiptail=$(command -v whiptail)
  set -e
  if ! [ -f /etc/default/zramit.conf ]; then
    if ! [ -z $iswhiptail ];then
      TERM=ansi whiptail --title "zramit" --msgbox "no config file. please install first" 14 58
    else
      echo "no config file. please install first"
    fi
  else
    _zram_fraction="1/2"
    _zram_algorithm="lz4"
    _zram_compfactor=''
    _zram_fixedsize=''
    _zram_streams=''
    _zram_number=''
    _zram_priority='32767'
    # load user config
    [ -f /etc/default/zramit.conf ] &&
      . /etc/default/zramit.conf
    # set expected compression ratio based on algorithm; this is a rough estimate
    # skip if already set in user config
    echo "# override fractional calculations and specify a fixed swap size\n# don't shoot yourself in the foot with this, or do" > /etc/default/zramit.conf
    echo $(ask "force size of real RAM used\nformat sizes like: 100M 250M 1.5G 2G etc.\ndefault unset" "_zram_fixedsize" $_zram_fixedsize) >> /etc/default/zramit.conf
    echo "\n# portion of real ram to use as zram swap (expression: "1/2", "0.5", etc)" >> /etc/default/zramit.conf
    echo $(ask "portion of real ram to use as zram swap\nexpression: "1/2", "0.5", etc\ndefault 1/2" "_zram_fraction" $_zram_fraction) >> /etc/default/zramit.conf
    echo "\n# compression algorithm to employ (lzo, lz4, zstd, lzo-rle)" >> /etc/default/zramit.conf
    echo $(ask_choice "compression algorithm to employ" "_zram_algorithm" "lz4;lzo-rle;lzo;zstd" $_zram_algorithm) >> /etc/default/zramit.conf
    echo "\n# number of streams (threads) from compression" >> /etc/default/zramit.conf
    echo $(ask "number of streams (threads) from compression\nleave blank for auto" "_zram_streams" $_zram_streams) >> /etc/default/zramit.conf
    echo "\n# number of swaps (1 zram swap per core , number of cores)" >> /etc/default/zramit.conf
    echo $(ask "number of swaps\ndefault is number of cores)\nleave blank for auto" "_zram_number" $_zram_number) >> /etc/default/zramit.conf
    echo "\n# priority of swaps (32767 is highest priority)\n# to manage different levels of swap" >> /etc/default/zramit.conf
    echo $(ask "priority of swaps\n32767 is highest priority\nto manage different levels of swap" "_zram_priority" $_zram_priority) >> /etc/default/zramit.conf
    echo "\n# expected compression ratio; this is a rough estimate" >> /etc/default/zramit.conf
    echo $(ask "expected compression ratio\nthis is a rough estimate\nleave blank for auto" "_zram_compfactor" $_zram_compfactor) >> /etc/default/zramit.conf
    echo "\n# Note:\n# set _zram_compfactor by hand if you use an algorithm other than lzo/lz4/zstd or if your\n# use case produces drastically different compression results than my estimates\n#\n# defaults if otherwise unset:\n#	lzo*|zstd)  _zram_compfactor=\"3\"   ;;\n#	lz4)        _zram_compfactor=\"2.5\" ;;\n#	*)          _zram_compfactor=\"2\"   ;;\n#" >> /etc/default/zramit.conf
    if ! [ -z $iswhiptail ];then
      TERM=ansi whiptail --clear --title "zramit" --msgbox "zramit configuration done" 14 78
    fi
  fi
}

_usage() { echo "Usage: $(basename "$0") (--install|--uninstall)"; }

ask() {
  [ $# -le 2 ] && res="" || res=$3
  if ! [ -z $iswhiptail ];then
    set +e
    res=$(TERM=ansi whiptail --title "zramit" --inputbox "$1\n\n$2" 14 58 $res 3>&1 1>&2 2>&3)
    set -e
  else
    >&2 echo "$1\n$2"
    >&2 printf "[$res] ?"
    read it
    ! [ -z $it ] && res=$it
  fi
  if [ -z $res ];then
    echo "#$2=\"\"\n"
  else
    echo "$2=\"$res\"\n"
  fi
}

ask_choice() {
  list=$3
  [ $# -le 3 ] && res="lz4" || res=$4
  choix=""
  elem="-"
  list2=""
  choix2=""
  nchoix=0
  while ! [ $elem = $list ];do
    nchoix=$((nchoix+1))
    elem=${list%%;*}
    list=${list#*;}
    ! [ -z $list2 ] && list2="$list2\n"
    list2="$list2$nchoix : $elem"
    choix="$choix $elem . "
    [ $elem = $res ] && choix="$choix ON" || choix="$choix OFF"
    [ $elem = $res ] && choix2=$nchoix
  done
  choix="$nchoix $choix"
  if ! [ -z $iswhiptail ];then
    set +e
    res=$(TERM=ansi whiptail --title "zramit" --radiolist "$1\n\n$2" 14 58 $choix 3>&1 1>&2 2>&3)
    set -e
  else
    >&2 echo "$1\n$2\n$list2"
    >&2 printf "[$choix2] ?"
    read it
    if ! [ -z $it ];then
      # transform number $it to text $res
      list2=$(echo $list2 | sed ':a;N;$!ba;s/\n/;/g')
      while ! [ "$elem" = "$list2" ];do
        elem=${list2%%;*}
        choixn=${elem%% :*}
        choix=${elem#*: }
        list2=${list2#*;}
        [ $choixn = $it ] && res=$choix
      done
    fi
  fi
  if [ -z $res ];then
    echo "#$2=\"\"\n"
  else
    echo "$2=\"$res\"\n"
  fi
}

calc() {
  case "$1" in [0-9]) n="$1" && shift ;; *) n=0 ;; esac
  awk "BEGIN{printf \"%.${n}f\", $*}"
}

_main "$@"
