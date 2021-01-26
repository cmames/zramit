#!/bin/sh

# make sure our environment is predictable
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
\unalias -a

# make sure $1 exists for 'set -u' so we can get through 'case "$1"' below
{ [ "$#" -eq "0" ] && set -- ""; } > /dev/null 2>&1

# get cores and threads
corespersocket=$(LC_ALL=C lscpu| grep "^Core(s) per socket:"|awk '{print $4}')
sockets=$(LC_ALL=C lscpu| grep "^Socket(s):"|awk '{print $2}')
threads=$(LC_ALL=C lscpu| grep "^CPU(s):"|awk '{print $2}')

# set sane defaults, see /etc/default/zramit for explanations
_zramit_fraction="1/2"
_zramit_algorithm="lz4"
_zramit_compfactor=""
_zramit_fixedsize=""
_zramit_streams="$threads"
_zramit_number=$((corespersocket*sockets))
_zramit_priority="20"

# load user config
[ -f /etc/default/zramit.conf ] &&
  . /etc/default/zramit.conf

# set expected compression ratio based on algorithm
# skip if already set in user config
if [ -z "$_zramit_compfactor" ]; then
  case $_zramit_algorithm in
    lzo* | zstd) _zramit_compfactor="3" ;;
    lz4) _zramit_compfactor="2.5" ;;
    *) _zramit_compfactor="2" ;;
  esac
fi

# main script:
_main() {
  if ! modprobe zram; then
    err "main: Failed to load zram module, exiting"
    return 1
  fi
  case "$1" in
    "init" | "start")
      if grep -q zram /proc/swaps; then
        err "main: zram swap already in use, exiting"
        return 1
      fi
      _init
      ;;
    "end" | "stop")
      if ! grep -q zram /proc/swaps; then
        err "main: no zram swaps to cleanup, exiting"
        return 1
      fi
      _end
      ;;
    *)
      _usage
      exit 1
      ;;
  esac
}

# initialize swap
_init() {

  if [ -n "$_zramit_fixedsize" ]; then
    if ! _regex_match "$_zramit_fixedsize" '^[[:digit:]]+(\.[[:digit:]]+)?(G|M)$'; then
      err "init: Invalid size '$_zramit_fixedsize'. Format sizes like: 100M 250M 1.5G 2G etc."
      exit 1
    fi
    # Use user supplied zram size
    mem=$(echo "($_zramit_fixedsize+$_zramit_number)/$_zramit_number-1" |bc)
  else
    # Calculate memory to use for zram
    totalmem=$(LC_ALL=C free | grep -e "^Mem:" | sed -e 's/^Mem: *//' -e 's/  *.*//')
    mem=$(echo "$totalmem*1024*$_zramit_compfactor*$_zramit_fraction/$_zramit_number" |bc)
  fi
  # to be sure of minimal size
  if [ "$mem" -lt 40960 ]; then
    mem=40960
  fi
  # NOTE: init is a little janky; zramctl sometimes fails if we don't wait after module
  #       load so retry a couple of times with slightly increasing delay before giving up
  _device=''
  for nbz in $(seq "$_zramit_number"); do
    for i in $(seq 3); do
      sleep $((i-1))
      echo "$nbz : zramctl -f -s $mem -a $_zramit_algorithm -t $_zramit_streams"
      _device=$(zramctl -f -s "$mem" -a "$_zramit_algorithm" -t "$_zramit_streams") || true
      [ -b "$_device" ] && break 1
    done
    _limit=$(echo "$mem/$_zramit_compfactor" |bc)
    _dev=$(echo "$_device" | awk -F/ '{print $3}')
    echo "$_limit" > "/sys/block/$_dev/mem_limit"
    if [ -b "$_device" ]; then
      # cleanup the device if swap setup fails
      trap '_rem_zdev "$_device"' EXIT
      mkswap "$_device"
      swapon -d -p "$_zramit_priority" "$_device"
      trap - EXIT
    else
      err "init: Failed to initialize zram device"
      return 1
    fi
  done
}

# end swapping and cleanup
_end() {
  ret="0"
  DEVICES=$(awk '/zram/ {print $1}' /proc/swaps)
  for d in $DEVICES; do
    swapoff "$d"
    if ! _rem_zdev "$d"; then
      err "end: Failed to remove zram device $d"
      ret=1
    fi
  done
  return "$ret"
}

# Remove zram device with retry
_rem_zdev() {
  if [ ! -b "$1" ]; then
    err "rem_zdev: No zram device '$1' to remove"
    return 1
  fi
  for i in $(seq 5); do
    sleep $((i-1))
    zramctl -r "$1" || true
    [ -b "$1" ] || break
  done
  if [ -b "$1" ]; then
    err "rem_zdev: Couldn't remove zram device '$1' after 5 attempts"
    return 1
  fi
  return 0
}

err() { echo "Err $*" >&2; }
_usage() { echo "Usage: $(basename "$0") (init|end)"; }
# posix compliant replacement for [[ $foo =~ bar-pattern ]]
_regex_match() { echo "$1" | grep -Eq "$2" > /dev/null 2>&1; }

_main "$@"
