#!/bin/sh

# get path
_path=$(grep "install_path" /etc/default/zramit.sav |awk '{print $2}')
_manpath=$(grep "man_path" /etc/default/zramit.sav |awk '{print $2}')

# ensure a predictable environment
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
\unalias -a

# set iswhiptail if whiptail is installed
if [ -z "$(command -v whiptail)" ];then
  iswhiptail=false
else
  iswhiptail=true
fi

# main body:
_main() {
  # ensure $1 exists so 'set -u' doesn't error out
  { [ "$#" -eq "0" ] && set -- ""; } > /dev/null 2>&1

  case "$1" in
    "--uninstall")
      # uninstall
      echo "You may be prompt for sudo"
      _uninstall
      ;;
    "--enable")
      # enable
      echo "You may be prompt for sudo"
      _enable
      ;;
    "--disable")
      # disable
      echo "You may be prompt for sudo"
      _disable
      ;;
    "--restart")
      # restart
      echo "You may be prompt for sudo"
      _restart
      ;;
    "--config")
      # config
      echo "You may be prompt for sudo"
      _config "$@"
      ;;
    "--status")
      # status
      _status
      ;;
    "--dstatus")
      # dynamic status
      _dstatus
      ;;
    *)
      # unknown flags, print usage and exit
      man zramit
      ;;
  esac
}

# enable function
_enable() {
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Reloading systemd unit files' 14 58
  else
    echo "Reloading systemd unit files"
  fi
  sudo systemctl daemon-reload
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Enable service' 14 58
  else
    echo "Enable service"
  fi
  sudo systemctl enable zramit.service
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Starting zramit service' 14 58
  else echo "Starting zramit service"
  fi
  sudo systemctl start zramit.service
  if $iswhiptail;then
    TERM=ansi whiptail --clear --title "zramit" --msgbox 'zramit enabled and started' 14 78
  else
    echo
    echo "zramit service enabled and started"
    echo
  fi
}

# disable function
_disable() {
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Stopping zramit service' 14 58
  else echo "Stopping zramit service"
  fi
  if systemctl -q is-active zramit.service; then
    sudo systemctl stop zramit.service
  fi
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Disabling service' 14 58
  else
    echo "disable service"
  fi
  if [ -f /etc/systemd/system/zramit.service ]; then
    sudo systemctl disable zramit.service
  fi
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Reloading systemd unit files' 14 58
  else
    echo "Reloading systemd unit files"
  fi
  sudo systemctl daemon-reload
  if $iswhiptail;then
    TERM=ansi whiptail --clear --title "zramit" --msgbox 'zramit disabled' 14 78
  else
    echo
    echo "zramit disabled"
    echo
  fi
}

# uninstall function
_uninstall() {
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Stopping zramit service' 14 58
  else echo "Stopping zramit service"
  fi
  if systemctl -q is-active zramit.service; then
    sudo systemctl stop zramit.service
  fi
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Uninstalling script and service...\n  [-] remove script\n  [ ] remove hibernate script\n  [ ] remove service\n  [ ] remove man page\n  [ ] remove config file' 14 58
  else
      echo "Unnstalling script and service ..."
      echo "  ├ remove script"
  fi
  if [ -f "$_path/zramit-script.sh" ]; then
    sudo rm -f "$_path/zramit-script.sh"
  fi
  if [ -f "$_path/zramit" ]; then
    sudo rm -f "$_path/zramit"
  fi
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Uninstalling script and service...\n  [X] remove script\n  [-] remove hibernate script\n  [ ] remove service\n  [ ] remove man page\n  [ ] remove config file' 14 58
  else
    echo "  ├ remove hibernate script"
  fi
  if [ -f /lib/systemd/system-slepp/zramit-hibernate.sh ]; then
    sudo rm -f /lib/systemd/system-sleep/zramit-hibernate.sh
  fi
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Uninstalling script and service...\n  [X] remove script\n  [X] remove hibernate script\n  [-] remove service\n  [ ] remove man page\n  [ ] remove config file' 14 58
  else
    echo "  ├ remove service"
  fi
  if [ -f /etc/systemd/system/zramit.service ]; then
    sudo systemctl disable zramit.service || true
    sudo rm -f /etc/systemd/system/zramit.service
  fi
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Uninstalling script and service...\n  [X] remove script\n  [X] remove hibernate script\n  [X] remove service\n  [-] remove man page\n  [ ] remove config file' 14 58
  else
    echo "  ├ remove man page"
  fi
  if [ -f "$_manpath/man8/zramit.8.gz" ]; then
    sudo rm -f "$_manpath/man8/zramit.8.gz"
  fi
  sudo mandb > /dev/null
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Uninstalling script and service...\n  [X] remove script\n  [X] remove hibernate script\n  [X] remove service\n  [X] remove man page\n  [-] remove config file' 14 58
  else
    echo "  └ remove config file"
  fi
  if [ -f /etc/default/zramit.conf ]; then
    sudo rm -f /etc/default/zramit.conf
  fi
  if [ -f /etc/default/zramit.sav ]; then
    sudo rm -f /etc/default/zramit.sav
  fi
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Reloading systemd unit files' 14 58
  else
    echo "Reloading systemd unit files"
  fi
  sudo systemctl daemon-reload
  if $iswhiptail;then
    TERM=ansi whiptail --clear --title "zramit" --msgbox 'zramit uninstalled' 14 78
  else
    echo
    echo "zramit service uninstalled"
    echo
  fi
}

# restart function
_restart() {
  if $iswhiptail;then
    TERM=ansi whiptail --title "zramit" --infobox 'Restarting ...' 14 58
  else
    echo "Restart zramit ..."
  fi
  sudo systemctl stop zramit.service
  sudo systemctl start zramit.service
  zramdetail=$(zramctl)
  if $iswhiptail;then
    echo "zram service restarted successfully!" >text_box
    echo "$zramdetail" >>text_box
    TERM=ansi whiptail --clear --title "zramit" --scrolltext --textbox text_box 14 78
    rm text_box
  else
    echo
    echo "zramit service restarted successfully!"
    echo
    echo "$zramdetail"
  fi
}

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

# status function
_status() {
  WH='\033[1;37m'
  NC='\033[0m'
  DEVICES=$(awk '/zram/ {print $1}' /proc/swaps)
  _out="${WH}"'DEVICE\tALGORITHM\tDATA\tCOMPRESSION\tCOMPRESSED\tZRAM-USED\tREAD_I/Os\tWRITE_I/Os'"${NC}"
  _tunc=0
  _tcomp=0
  _tlim=0
  _tread=0
  _twrite=0
  for _device in $DEVICES; do
    _dir=/sys$(udevadm info --query=path --name="$_device")
    _unc=$(awk '{print $1}' "$_dir"/mm_stat)
    _comp=$(awk '{print $3}' "$_dir"/mm_stat)
    _lim=$(awk '{print $4}' "$_dir"/mm_stat)
    _read=$(awk '{print $1}' "$_dir"/stat)
    _write=$(awk '{print $5}' "$_dir"/stat)
    _alg=$(sed -e 's/.*\[\(.*\)\].*/\1/' "$_dir"/comp_algorithm)
    _out="$_out"'\n'"$_device#$_alg#$(formatbyte "$_unc")#$(echo "scale=2;$_unc/$_comp" |bc)x#$(formatbyte "$_comp")#$(echo "scale=2;100*$_comp/$_lim" |bc)%#$_read#$_write"
    _tunc=$(echo "$_tunc+$_unc" |bc)
    _tcomp=$(echo "$_tcomp+$_comp" |bc)
    _tlim=$(echo "$_tlim+$_lim" |bc)
    _tread=$(echo "$_tread+$_read" |bc)
    _twrite=$(echo "$_twrite+$_write" |bc)
  done
  _out="$_out"'\n'"${WH}TOTAL#---#$(formatbyte "$_tunc")#$(echo "scale=2;$_tunc/$_tcomp" |bc)x#$(formatbyte "$_tcomp")#$(echo "scale=2;100*$_tcomp/$_tlim" |bc)%#$_tread#$_twrite${NC}"
  echo "$_out" |awk '{split($0,a,"#"); print a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8]}' OFS='\t' |column -t
}

# dstatus function
_dstatus() {
  clear
  WH='\033[1;37m'
  NC='\033[0m'
  old_tty_settings=$(stty -g)
  trap '' INT QUIT TERM EXIT
  stty -icanon time 0 min 0
  tput sc
  while true;do
    _status
    echo "${WH}press x to exit${NC}"
    input=$(head -c1)
    if [ "$input" = "x" ] || [ "$input" = "X" ]; then
      stty "$old_tty_settings"
      break
    fi
    sleep 1
    tput rc
    tput ed
  done
  trap - INT QUIT TERM EXIT
}

# other functions
formatbyte() {
  # formatbyte number precision
  # format a number in Byte format with precision
  _val=${1:-0}
  _prec=${2:-2}
  _suff="B"
  if [ "$_val" -gt 1099511627776 ];then
    _suff="TB"
    _val=$(echo "scale=$_prec; $_val/1099511627776" |bc)
  else
    if [ "$_val" -gt 1073741824 ];then
      _suff="GB"
      _val=$(echo "scale=$_prec; $_val/1073741824" |bc)
    else
      if [ "$_val" -gt 1048576 ];then
        _suff="MB"
        _val=$(echo "scale=$_prec; $_val/1048576" |bc)
      else
        if [ "$_val" -gt 1024 ];then
          _suff="KB"
          _val=$(echo "scale=$_prec; $_val/1024" |bc)
        fi
      fi
    fi
  fi
  echo "$_val$_suff"
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

_main "$@"
