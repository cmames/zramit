#!/bin/sh

echo "You may be prompt for sudo"

# check if utils are installed
for _require in 'sed' 'grep' 'awk' 'column' 'bc' 'lscpu' 'modprobe' 'sleep' 'mkswap' 'swapon' 'swapoff' 'zramctl' 'systemctl' 'sysctl' 'install' 'manpath'
do
  [ -n "$(command -v $_require)" ]  || {
    echo "This script requires $_require"
    echo " try : sudo apt-get install $_require"
    exit 1
  }
done

# change path destination for some system which don't have /usr/local/sbin
# and choose a path in PATH
if [ "$(echo "$PATH" | grep -c "/usr/local/sbin")" = 1 ];then
  _path="/usr/local/sbin"
else
  if [ "$(echo "$PATH" | grep -c "/usr/sbin")" = 1 ];then
    _path="/usr/sbin"
  else
    if [ "$(echo "$PATH" | grep -c "/usr/local/bin")" = 1 ];then
      _path="/usr/local/bin"
    else _path="/usr/bin"
    fi
  fi
fi
# choose a path in manpath
if [ "$(manpath | grep -c "/usr/local/man")" = 1 ];then
  _manpath="/usr/local/man"
else
  if [ "$(manpath | grep -c "/usr/local/share/man")" = 1 ];then
    _manpath="/usr/local/share/man"
  else _manpath="/usr/share/man"
  fi
fi
# get original min_free setup
_original_min_free=$(sysctl vm.min_free_kbytes |awk '{print $3}')
_transparent_hugepage=$(cat /sys/kernel/mm/transparent_hugepage/enabled | sed -e 's/.*\[\(.*\)\].*/\1/')
# save original parameters
sudo sh -c "echo \"# data for zramit run and uninstall do not delete this file\" > /etc/default/zramit.sav"
sudo sh -c "echo \"install_path $_path\" >> /etc/default/zramit.sav"
sudo sh -c "echo \"man_path $_manpath\" >> /etc/default/zramit.sav"
sudo sh -c "echo \"original_min_free $_original_min_free\" >> /etc/default/zramit.sav"
sudo sh -c "echo \"transparent_hugepage $_transparent_hugepage\" >> /etc/default/zramit.sav"
# ensure a predictable environment
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
\unalias -a

# set iswhiptail if whiptail is installed
if [ -z "$(command -v whiptail)" ];then
  iswhiptail=false
else
  iswhiptail=true
fi

# congig function
_config() {
  _rest=$1
  if ! [ -f /etc/default/zramit.conf ]; then
    if $iswhiptail;then
      TERM=ansi whiptail --title "zramit" --msgbox 'no config file. please install first' 14 58
    else
      echo "no config file. please install first"
    fi
  else
    _zramit_fraction="1/2"
    _zramit_algorithm="lz4"
    _zramit_compfactor=''
    _zramit_fixedsize=''
#    _zramit_streams=''
    _zramit_number=''
    _zramit_priority='32767'
    # load user config
    [ -f /etc/default/zramit.conf ] &&
      . /etc/default/zramit.conf
    # set expected compression ratio based on algorithm
    # skip if already set in user config
    sudo sh -c 'echo "# override fractional calculations and specify a fixed swap size\n# don t shoot yourself in the foot with this, or do" > /etc/default/zramit.conf'
    _temp=$(ask 'force size of real RAM used\nformat sizes like: 100M 250M 1.5G 2G etc.\ndefault unset' "_zramit_fixedsize" "$_zramit_fixedsize" |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# portion of real ram to use as zram swap (expression: "1/2", "0.5", etc)" >> /etc/default/zramit.conf'
    _temp=$(ask 'portion of real ram to use as zram swap\nexpression: "1/2", "0.5", etc\ndefault 1/2' "_zramit_fraction" "$_zramit_fraction" |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# compression algorithm to employ (lzo, lz4, zstd, lzo-rle)" >> /etc/default/zramit.conf'
    _temp=$(ask_choice "compression algorithm to employ" "_zramit_algorithm" "lz4;lzo-rle;lzo;zstd" "$_zramit_algorithm" |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# number of streams (threads) from compression\n#DEPRECATED\n#_zramit_streams=\"\"" >> /etc/default/zramit.conf'
#    sudo sh -c 'echo $(ask "number of streams (threads) from compression\nleave blank for auto" "_zramit_streams" $_zramit_streams) >> /etc/default/zramit.conf'
    sudo sh -c 'echo "\n# number of swaps (1 zram swap per core , number of cores)" >> /etc/default/zramit.conf'
    _temp=$(ask 'number of swaps\ndefault is number of cores)\nleave blank for auto' "_zramit_number" "$_zramit_number" |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# priority of swaps (32767 is highest priority)\n# to manage different levels of swap" >> /etc/default/zramit.conf'
    _temp=$(ask 'priority of swaps\n32767 is highest priority\nto manage different levels of swap' "_zramit_priority" "$_zramit_priority" |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# expected compression ratio; this is a rough estimate" >> /etc/default/zramit.conf'
    _temp=$(ask 'expected compression ratio\nthis is a rough estimate\nleave blank for auto' "_zramit_compfactor" "$_zramit_compfactor" |sed 's/"/\\"/g' |sed 's/\\\\/\\/g')
    _temp="echo \"$_temp\" >> /etc/default/zramit.conf"
    sudo sh -c "$_temp"
    sudo sh -c 'echo "\n# Note:\n# set _zramit_compfactor by hand if you use an algorithm other than lzo/lz4/zstd or if your\n# use case produces drastically different compression results than my estimates\n#\n# defaults if otherwise unset:\n#	lzo*|zstd)  _zramit_compfactor=\"3\"   ;;\n#	lz4)        _zramit_compfactor=\"2.5\" ;;\n#	*)          _zramit_compfactor=\"2\"   ;;\n#" >> /etc/default/zramit.conf'
    if $iswhiptail;then
      TERM=ansi whiptail --clear --title "zramit" --msgbox 'zramit configuration done' 14 78
    fi
    [ "$_rest" != "norestart" ] && _restart
  fi
  return 0
}

ask() {
  # use read ou use whiptail
  [ $# -le 2 ] && res="" || res=$3
  if $iswhiptail;then
    set +e
    res=$(TERM=ansi whiptail --title "zramit" --inputbox "$1"'\n\n'"$2" 14 58 "$res" 3>&1 1>&2 2>&3)
    set -e
  else
    >&2 echo "$1"
    >&2 echo "$2"
    >&2 printf "0 for auto [%s] ?" "$res"
    read -r it
    [ -n "$it" ] && res=$it
  fi
  if [ -z "$res" ] || [ "$res" = "0" ];then
    echo "#$2=\"\""
    echo ""
  else
    echo "$2=\"$res\""
    echo ""
  fi
}

ask_choice() {
  # print a list and use read or use whiptail whith radiolist
  list=$3
  [ $# -le 3 ] && res="lz4" || res=$4
  choix=""
  elem="-"
  list2=""
  choix2=""
  nchoix=0
  while ! [ "$elem" = "$list" ];do
    nchoix=$((nchoix+1))
    elem=${list%%;*}
    list=${list#*;}
    [ -n "$list2" ] && list2="$list2"'\n'
    list2="$list2$nchoix : $elem"
    choix="$choix $elem . "
    [ "$elem" = "$res" ] && choix="$choix ON" || choix="$choix OFF"
    [ "$elem" = "$res" ] && choix2=$nchoix
  done
  choix="$nchoix $choix"
  if $iswhiptail;then
    set +e
    res=$(TERM=ansi whiptail --title "zramit" --radiolist "$1"'\n\n'"$2" 14 58 ${choix} 3>&1 1>&2 2>&3)
    set -e
  else
    >&2 echo "$1"
    >&2 echo "$2"
    >&2 echo "$list2"
    >&2 printf "[%s] ?" "$choix2"
    read -r it
    if [ -n "$it" ];then
      # transform number $it to text $res
      list2=$(echo "$list2" | sed ':a;N;$!ba;s/\n/;/g')
      while ! [ "$elem" = "$list2" ];do
        elem=${list2%%;*}
        choixn=${elem%% :*}
        choix=${elem#*: }
        list2=${list2#*;}
        [ "$choixn" = "$it" ] && res=$choix
      done
    fi
  fi
  if [ -z "$res" ];then
    echo "#$2=\"\""
    echo ""
  else
    echo "$2=\"$res\""
    echo ""
  fi
}


if [ ! -f zramit-script.sh ] ||
   [ ! -f zramit.sh ] ||
   [ ! -f zramit-hibernate.sh ] ||
   [ ! -f service/zramit.config ] ||
   [ ! -f service/zramit.man ] ||
   [ ! -f service/zramit.service ] ;then
  WH='\033[1;37m'
  RR='\033[1;31m'
  NC='\033[0m'
  echo "${RR}ERR[file not found]:${NC} You must be in the original zramit directory to run install.sh"
  echo " Try ${WH}zramit --config${NC} to change configuration and restart zramit"
  exit 1
fi
# Installation
if $iswhiptail ;then
  TERM=ansi whiptail --title "zramit" --infobox 'Prepare install\n\nplease wait ...' 14 58
else echo "Prepare install"
fi
configdiff=''
if systemctl -q is-active zramit.service; then
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Stopping zramit service' 14 58
  else echo "Stopping zramit service"
  fi
  sudo systemctl stop zramit.service
fi
if $iswhiptail;then
  TERM=ansi whiptail --title "zramit" --infobox 'Installing script and service...\n  [-] installing script\n  [ ] installing hibernate script\n  [ ] installing service\n  [ ] installing man page\n  [ ] installing config file' 14 58
else
    echo "Installing script and service ..."
    echo "  ├ installing script"
fi
sudo install -o root zramit-script.sh "$_path/zramit-script.sh"
sudo install -o root zramit.sh "$_path/zramit"
if $iswhiptail;then
  TERM=ansi whiptail --title "zramit" --infobox 'Installing script and service...\n  [X] installing script\n  [-] installing hibernate script\n  [ ] installing service\n  [ ] installing man page\n  [ ] installing config file' 14 58
else
  echo "  ├ installing hibernate script"
fi
sudo install -o root zramit-hibernate.sh /lib/systemd/system-sleep/zramit-hibernate.sh
if $iswhiptail;then
  TERM=ansi whiptail --title "zramit" --infobox 'Installing script and service...\n  [X] installing script\n  [X] installing hibernate script\n  [-] installing service\n  [ ] installing man page\n  [ ] installing config file' 14 58
else
  echo "  ├ installing service"
fi
# replace path in service
sudo install -o root -m 0644 service/zramit.service /etc/systemd/system/zramit.service
sync
sudo sed -i -e "s~#PATH~$_path~g" /etc/systemd/system/zramit.service
if $iswhiptail;then
  TERM=ansi whiptail --title "zramit" --infobox 'Installing script and service...\n  [X] installing script\n  [X] installing hibernate script\n  [X] installing service\n  [-] installing man page\n  [ ] installing config file' 14 58
else
  echo "  ├ installing man page"
fi
if [ ! -d "$_manpath/man8" ]; then
  sudo mkdir "$_manpath/man8"
fi
sudo install -o root -m 0644 service/zramit.man "$_manpath/man8/zramit.8"
sudo gzip "$_manpath/man8/zramit.8"
sudo mandb > /dev/null
if $iswhiptail;then
  TERM=ansi whiptail --title "zramit" --infobox 'Installing script and service...\n  [X] installing script\n  [X] installing hibernate script\n  [X] installing service\n  [X] installing man page\n  [-] installing config file' 14 58
else
  echo "  └ installing config file"
fi
if [ -f /etc/default/zramit.conf ]; then
  {
    set +e
    grep "_zram" /etc/default/zramit.conf > oldconf
    grep "_zram" service/zramit.config > newconf
    configdiff=$(diff -u --suppress-common-line oldconf newconf | grep "^[-+]" | sed -e 's/oldconf.*/installed config/g' -e 's/newconf.*/package config/g')
    rm oldconf
    rm newconf
    set -e
  } > /dev/null 2>&1
  if [ -n "$configdiff" ]; then
    yn=''
    if $iswhiptail;then
      if (TERM=ansi whiptail --title "zramit" --yesno 'Installed configuration differs from packaged version\n\n would you want to see differences?' 14 58);then
        echo "$configdiff">text_box
        sed -i -e "s/^</installed </g" text_box
        sed -i -e "s/^>/package >/g" text_box
        TERM=ansi whiptail --title "zramit" --scrolltext --textbox text_box 14 78
        rm text_box
      fi
      if (TERM=ansi whiptail --title "zramit" --yesno 'Installed configuration differs from packaged version\n\n install packaged config?' 14 58);then
        install -o root -m 0644 --backup --suffix=".oldconfig" service/zramit.config /etc/default/zramit.conf
        TERM=ansi whiptail --title "zramit" --msgbox 'Original config backed up as /etc/default/zramit.oldconfig' 14 58
      fi
    else
      echo "Installed configuration differs from packaged version."
      echo
      echo "Install packaged config? Original will be backed up as /etc/default/zramit.oldconfig"
      while true; do
        echo "(y)Install packaged config / (n)Keep current / (s)Show diff"
        printf "[y/n/s]: "
        read -r yn
        case "$yn" in
          [Yy]*)
            echo "Installing packaged config ..."
            sudo install -o root -m 0644 --backup --suffix=".oldconfig" service/zramit.config /etc/default/zramit.conf
            break
            ;;
          [Nn]*) break ;;
          [Ss]*)
            echo "$configdiff"
            echo ""
            ;;
        esac
      done
    fi
  fi
else
  sudo install -o root -m 0644 -b service/zramit.config /etc/default/zramit.conf
  if $iswhiptail;then
    if (TERM=ansi whiptail --title "zramit" --yesno 'Would you want to use the config assistant?' 14 58);then
      _config norestart
    fi
  else
    echo "Would you want to use the config assistant?"
    printf "[y/n]: "
    read -r yn
    if [ "$yn" = "Y" ] || [ "$yn" = "y" ];then
      _config norestart
    fi
  fi
fi
if $iswhiptail;then
  TERM=ansi whiptail --title "zramit" --infobox 'Installing script and service...\n  [X] installing script\n  [X] installing hibernate script\n  [X] installing service\n  [X] installing config file' 14 58
  sleep 1 # wait to let user read :)
fi
if $iswhiptail;then
  TERM=ansi whiptail --title "zramit" --infobox 'Reloading systemd unit files and enabling boot-time service ...' 14 58
else
  echo "Reloading systemd unit files and enabling boot-time service ..."
fi
sudo systemctl daemon-reload
sudo systemctl enable zramit.service
if $iswhiptail;then
  TERM=ansi whiptail --title "zramit" --infobox 'Starting zram  service ...' 14 58
else
  echo "Starting zramit service ..."
fi
sudo systemctl start zramit.service
zramdetail=$(zramctl)
if $iswhiptail;then
  echo "zram service installed successfully!" >text_box
  echo "$zramdetail" >>text_box
  TERM=ansi whiptail --clear --title "zramit" --scrolltext --textbox text_box 14 78
  rm text_box
else
  echo
  echo "zramit service installed successfully!"
  echo
  echo "$zramdetail"
fi