#!/bin/sh

if [ "${1}" = "pre" ]
 then
  # Do the thing you want before suspend here, e.g.:
  logger -t zram-hibernate "pre-hibernate"
  DEVICES=$(awk '/zram/ {print $1}' /proc/swaps)
  for d in $DEVICES; do
    swapoff -v "$d" | logger -t zram-hibernate
    zramctl -r "$d"
  done
elif [ "${1}" = "post" ]
 then
  # Do the thing you want after resume here, e.g.:
  /usr/local/sbin/zramit.sh init
  swapfiles=$(cat /proc/swaps |grep -v "zram" |grep "file" |awk '{print $1}' |sed -e ':a;N;$!ba;s/\n/ /g')
  echo "nice -19 swapoff -v $swapfiles && swapon -v $swapfiles &" | at now + 3 minutes
fi
