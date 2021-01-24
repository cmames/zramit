#!/bin/sh

if [ "$1" = "pre" ]
 then
  # Do the thing you want before suspend here, e.g.:
  logger -t zramit "pre-$2"
  if [ "$2" = "hibernate" ] || [ "$2" = "hybrid-sleep" ];then
    /usr/local/sbin/zramit-script.sh end
  fi
elif [ "$1" = "post" ]
 then
  # Do the thing you want after resume here, e.g.:
  logger -t zramit "post-$2"
  if [ "$2" = "hibernate" ] || [ "$2" = "hybrid-sleep" ];then
    /usr/local/sbin/zramit-script.sh init
  fi
  swapfiles=$(grep -v "zram" /proc/swaps |grep "file" |awk '{print $1}' |sed -e ':a;N;$!ba;s/\n/ /g')
  echo "nice -19 swapoff -v $swapfiles && swapon -d -v $swapfiles &" | at now + 3 minutes
fi
