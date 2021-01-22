#!/bin/sh
case "$(readlink /proc/$$/exe)" in */bash) set -euo pipefail ;; *) set -eu ;; esac

# ensure a predictable environment
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
\unalias -a

for _require in 'sed' 'grep' 'awk' 'column' 'bc' 'readlnk' 'lscpu' 'modprobe' 'sleep' 'mkswap' 'swapon' 'swapoff' 'zramctl' 'systemctl' 'install'
do
  [ -n $(command -v $_require) ]  || { echo "This script requires $_require\n try : sudo apt-get install $_require" && exit 1; }
done

if [ -z $(command -v whiptail) ];then
  iswhiptail=false
else
  iswhiptail=true
fi

# installer main body:
_main() {
  # ensure $1 exists so 'set -u' doesn't error out
  { [ "$#" -eq "0" ] && set -- ""; } > /dev/null 2>&1

  case "$1" in
    "--uninstall")
      # uninstall
      sudo echo "You may be prompt for sudo"
      _uninstall
      ;;
    "--install")
      # install
      sudo echo "You may be prompt for sudo"
      _install "$@"
      ;;
    "--restart")
      # restart
      sudo echo "You may be prompt for sudo"
      _restart
      ;;
    "--config")
      # config
      sudo echo "You may be prompt for sudo"
      _config "$@"
      ;;
    "--status")
      # status
      _status
      ;;
    "--dstatus")
      # status
      _dstatus
      ;;
    *)
      # unknown flags, print usage and exit
      _usage
      ;;
  esac
  exit 0
}

_install() {
  if $iswhiptail ;then
    TERM=ansi whiptail --title "zramit" --infobox "Prepare install\n\nplease wait ..." 14 58
  else echo "Prepare install"
  fi

  configdiff=''
  newconfig=''
  if systemctl -q is-active zramit.service; then
    if $iswhiptail;then
      sleep 1
      TERM=ansi whiptail --title "zramit" --infobox "Stopping zramit service" 14 58
    else echo "Stopping zramit service"
    fi
    sudo systemctl stop zramit.service
  fi

  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Installing script and service...\n  [-] installing script\n  [ ] installing hibernate script\n  [ ] installing service\n  [ ] installing config file" 14 58
  else
      echo "Installing script and service ..."
      echo "  ├ installing script"
  fi
  sudo install -o root zramit-script.sh /usr/local/sbin/zramit-script.sh
  sudo install -o root zramit.sh /usr/local/sbin/zramit

  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Installing script and service...\n  [X] installing script\n  [-] installing hibernate script\n  [ ] installing service\n  [ ] installing config file" 14 58
  else
    echo "  ├ installing hibernate script"
  fi
  sudo install -o root zramit-hibernate.sh /lib/systemd/system-sleep/zramit-hibernate.sh
  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Installing script and service...\n  [X] installing script\n  [X] installing hibernate script\n  [-] installing service\n  [ ] installing config file" 14 58
  else
    echo "  ├ installing service"
  fi
  sudo install -o root -m 0644 service/zramit.service /etc/systemd/system/zramit.service
  if $iswhiptail;then
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
      if $iswhiptail;then
        sleep 1
        if (TERM=ansi whiptail --title "zramit" --yesno "Installed configuration differs from packaged version\n\n would you want to see differences?" 14 58);then
          echo "$configdiff">text_box
          sed -i -e "s/^</installed </g" text_box
          sed -i -e "s/^>/package >/g" text_box
          TERM=ansi whiptail --title "zramit" --scrolltext --textbox text_box 14 78
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
    sudo install -o root -m 0644 -b service/zramit.config /etc/default/zramit.conf
    if $iswhiptail;then
      if (TERM=ansi whiptail --title "zramit" --yesno "Would you want to use the config assistant?" 14 58);then
        _config norestart
      fi
    else
      echo "Would you want to use the config assistant?"
      printf "[y/n]: "
      read yn
      case "$yn" in
        [Yy]*)
          _config norestart
          break
          ;;
        *) break ;;
      esac
    fi
  fi
  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Installing script and service...\n  [X] installing script\n  [X] installing hibernate script\n  [X] installing service\n  [X] installing config file" 14 58
  fi

  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Reloading systemd unit files and enabling boot-time service ..." 14 58
  else
    echo "Reloading systemd unit files and enabling boot-time service ..."
  fi
  sudo systemctl daemon-reload
  sudo systemctl enable zramit.service

  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox "Starting zram  service ..." 14 58
  else
    echo "Starting zramit service ..."
  fi
  sudo systemctl start zramit.service
  zramdetail=$(zramctl)

  if $iswhiptail;then
    echo "zram service installed successfully!\n\n$zramdetail">text_box
    TERM=ansi whiptail --clear --title "zramit" --scrolltext --textbox text_box 14 78
    rm text_box
  else
    echo
    echo "zramit service installed successfully!"
    echo
    echo "$zramdetail"
  fi
}

_uninstall() {
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox "Stopping zramit service" 14 58
  else echo "Stopping zramit service"
  fi
  if systemctl -q is-active zramit.service; then
    sudo systemctl stop zramit.service
  fi

  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Uninstalling script and service...\n  [-] remove script\n  [ ] remove hibernate script\n  [ ] remove service\n  [ ] remove config file" 14 58
  else
      echo "Unnstalling script and service ..."
      echo "  ├ remove script"
  fi
  if [ -f /usr/local/sbin/zramit-script.sh ]; then
    sudo rm -f /usr/local/sbin/zramit-script.sh
  fi
  if [ -f /usr/local/sbin/zramit ]; then
    sudo rm -f /usr/local/sbin/zramit
  fi
  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Uninstalling script and service...\n  [X] remove script\n  [-] remove hibernate script\n  [ ] remove service\n  [ ] remove config file" 14 58
  else
    echo "  ├ remove hibernate script"
  fi
  if [ -f /lib/systemd/system-slepp/zramit-hibernate.sh ]; then
    sudo rm -f /lib/systemd/system-sleep/zramit-hibernate.sh
  fi
  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Uninstalling script and service...\n  [X] remove script\n  [X] remove hibernate script\n  [-] remove service\n  [ ] remove config file" 14 58
  else
    echo "  ├ remove service"
  fi
  if [ -f /etc/systemd/system/zramit.service ]; then
    sudo systemctl disable zramit.service || true
    sudo rm -f /etc/systemd/system/zramit.service
  fi
  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Uninstalling script and service...\n  [X] remove script\n  [X] remove hibernate script\n  [X] remove service\n  [-] remove config file" 14 58
  else
    echo "  └ remove config file"
  fi
  if [ -f /etc/default/zramit.conf ]; then
    sudo rm -f /etc/default/zramit.conf
  fi

  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Reloading systemd unit files" 14 58
  else
    echo "Reloading systemd unit files"
  fi
  sudo systemctl daemon-reload

  if $iswhiptail;then
    TERM=ansi whiptail --clear --title "zramit" --msgbox "zramit uninstalled" 14 78
  else
    echo
    echo "zramit service uninstalled"
    echo
  fi
}

_restart() {
  if $iswhiptail;then
    sleep 1
    TERM=ansi whiptail --title "zramit" --infobox "Restarting ..." 14 58
  else
    echo "Restart zramit ..."
  fi
  sudo systemctl stop zramit.service
  sudo systemctl start zramit.service
  zramdetail=$(zramctl)
  if $iswhiptail;then
    echo "zram service restarted successfully!\n\n$zramdetail">text_box
    TERM=ansi whiptail --clear --title "zramit" --scrolltext --textbox text_box 14 78
    rm text_box
  else
    echo
    echo "zramit service restarted successfully!"
    echo
    echo "$zramdetail"
  fi

}

_config() {
  _rest=$1
  if ! [ -f /etc/default/zramit.conf ]; then
    if $iswhiptail;then
      TERM=ansi whiptail --title "zramit" --msgbox "no config file. please install first" 14 58
    else
      echo "no config file. please install first"
    fi
  else
    _zramit_fraction="1/2"
    _zramit_algorithm="lz4"
    _zramit_compfactor=''
    _zramit_fixedsize=''
    _zramit_streams=''
    _zramit_number=''
    _zramit_priority='32767'
    # load user config
    [ -f /etc/default/zramit.conf ] &&
      . /etc/default/zramit.conf
    # set expected compression ratio based on algorithm; this is a rough estimate
    # skip if already set in user config
    sudo sh -c 'echo "# override fractional calculations and specify a fixed swap size\n# don t shoot yourself in the foot with this, or do" > /etc/default/zramit.conf'
    _temp=$(ask "force size of real RAM used\nformat sizes like: 100M 250M 1.5G 2G etc.\ndefault unset" "_zramit_fixedsize" $_zramit_fixedsize |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# portion of real ram to use as zram swap (expression: "1/2", "0.5", etc)" >> /etc/default/zramit.conf'
    _temp=$(ask "portion of real ram to use as zram swap\nexpression: "1/2", "0.5", etc\ndefault 1/2" "_zramit_fraction" $_zramit_fraction |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# compression algorithm to employ (lzo, lz4, zstd, lzo-rle)" >> /etc/default/zramit.conf'
    _temp=$(ask_choice "compression algorithm to employ" "_zramit_algorithm" "lz4;lzo-rle;lzo;zstd" $_zramit_algorithm |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# number of streams (threads) from compression\n#DEPRECATED\n#_zramit_streams=\"\"" >> /etc/default/zramit.conf'
#    sudo sh -c 'echo $(ask "number of streams (threads) from compression\nleave blank for auto" "_zramit_streams" $_zramit_streams) >> /etc/default/zramit.conf'
    sudo sh -c 'echo "\n# number of swaps (1 zram swap per core , number of cores)" >> /etc/default/zramit.conf'
    _temp=$(ask "number of swaps\ndefault is number of cores)\nleave blank for auto" "_zramit_number" $_zramit_number |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    echo $_temp
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# priority of swaps (32767 is highest priority)\n# to manage different levels of swap" >> /etc/default/zramit.conf'
    _temp=$(ask "priority of swaps\n32767 is highest priority\nto manage different levels of swap" "_zramit_priority" $_zramit_priority |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# expected compression ratio; this is a rough estimate" >> /etc/default/zramit.conf'
    _temp=$(ask "expected compression ratio\nthis is a rough estimate\nleave blank for auto" "_zramit_compfactor" $_zramit_compfactor |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# Note:\n# set _zramit_compfactor by hand if you use an algorithm other than lzo/lz4/zstd or if your\n# use case produces drastically different compression results than my estimates\n#\n# defaults if otherwise unset:\n#	lzo*|zstd)  _zramit_compfactor=\"3\"   ;;\n#	lz4)        _zramit_compfactor=\"2.5\" ;;\n#	*)          _zramit_compfactor=\"2\"   ;;\n#" >> /etc/default/zramit.conf'
    if $iswhiptail;then
      TERM=ansi whiptail --clear --title "zramit" --msgbox "zramit configuration done" 14 78
    fi
    [ "$_rest" != "norestart" ] && _restart
  fi
  return 0
}

_status() {
  DEVICES=$(awk '/zram/ {print $1}' /proc/swaps)
  _out="DEVICE\tALGORITHM\tDATA\tCOMPRESSION\tCOMPRESSED\tZRAM-USED\tREAD_I/Os\tWRITE_I/Os"
  for _device in $DEVICES; do
    _dir=/sys`udevadm info --query=path --name=$_device`
    _unc=$(awk '{print $1}' $_dir/mm_stat)
    _comp=$(awk '{print $3}' $_dir/mm_stat)
    _lim=$(awk '{print $4}' $_dir/mm_stat)
    _read=$(awk '{print $1}' $_dir/stat)
    _write=$(awk '{print $5}' $_dir/stat)
    _alg=$(cat $_dir/comp_algorithm | sed -e "s/.*\[\(.*\)\].*/\1/")
    _used=$(formatbyte $_comp)
    _out="$_out\n$_device#$_alg#$(formatbyte $_unc)#$(echo "scale=2;$_unc/$_comp" |bc)x#$(formatbyte $_comp)#$(echo "scale=2;100*$_comp/$_lim" |bc)%#$_read#$_write"
  done
  echo $_out |awk '{split($0,a,"#"); print a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8]}' OFS='\t' |column -t
}

_dstatus() {
  clear
  WH='\033[1;37m'
  NC='\033[0m'
  old_tty_settings=$(stty -g)
  stty -icanon time 0 min 0
  tput sc
  while true;do
    _status
    echo "$WH press x to exit$NC"
    input=$(head -c1)
    if [ "$input" = "x" ] || [ "$input" = "X" ]; then
      stty "$old_tty_settings"
      break
    fi
    sleep 1
    tput rc
    tput ed
  done
}

_usage() {
  WH='\033[1;37m'
  NC='\033[0m'
  echo "Install zramit\n    ${WH}./zramit.sh --install${NC}"
  echo "Uninstall zramit\n    ${WH}zramit --uninstall${NC}"
  echo "Configure zramit :\n    ${WH}zramit --config${NC}"
  echo "Restart zramit :\n    ${WH}zramit --restart${NC}"
  echo "Show zramit status :\n    ${WH}zramit --status${NC}"
  echo "Dynamic status (auto refresh) :\n    ${WH}zramit --dstatus${NC}"
 }

formatbyte() {
  # formatbyte number precision
  # format a number in Byte format with precision
  _val=${1:-0}
  _prec=${2:-2}
  _suff="B"
  if [ $_val -gt 1099511627776 ];then
    _suff="TB"
    _val=$(echo "scale=2; $_val/1099511627776" |bc)
  else
    if [ $_val -gt 1073741824 ];then
      _suff="GB"
      _val=$(echo "scale=2; $_val/1073741824" |bc)
    else
      if [ $_val -gt 1048576 ];then
        _suff="MB"
        _val=$(echo "scale=2; $_val/1048576" |bc)
      else
        if [ $_val -gt 1024 ];then
          _suff="KB"
          _val=$(echo "scale=2; $_val/1024" |bc)
        fi
      fi
    fi
  fi
  echo "$_val$_suff"
}

ask() {
  [ $# -le 2 ] && res="" || res=$3
  if $iswhiptail;then
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
  if $iswhiptail;then
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

_main "$@"
