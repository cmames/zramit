#!/bin/sh

if [ "$1" = "pre" ]
 then
  # Stop zram before hibernate or hybrid-sleep
  logger -t zramit "pre-$2"
  if [ "$2" = "hibernate" ] || [ "$2" = "hybrid-sleep" ];then
    /usr/local/sbin/zramit-script.sh end
  fi
elif [ "$1" = "post" ]
 then
  # Start zram after hibernate or hybrid-sleep
  logger -t zramit "post-$2"
  if [ "$2" = "hibernate" ] || [ "$2" = "hybrid-sleep" ];then
    /usr/local/sbin/zramit-script.sh init
  fi
  _swapfiles=$(grep -v "zram" /proc/swaps |grep "file" |awk '{print $1}' |sed -e ':a;N;$!ba;s/\n/ /g')
  # friendly clear swapfiles if exist
    echo "nice -19 swapoff -v $_swapfiles && swapon -d -v $_swapfiles" | at now + 3 minutes
fi
