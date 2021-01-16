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
  echo "swapoff -v /swapfile && swapon -v /swapfile &" | at now + 2 minutes
fi
