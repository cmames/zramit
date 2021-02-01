#!/bin/sh

# get install path
_path=$(grep "install_path" /etc/default/zramit.sav |awk '{print $2}')

if [ "$1" = "pre" ]
 then
  # Stop zram before hibernate or hybrid-sleep
  logger -t zramit "pre-$2"
  if [ "$2" = "hibernate" ] || [ "$2" = "hybrid-sleep" ];then
    "$_path"/zramit-script.sh end
  fi
elif [ "$1" = "post" ]
 then
  # Start zram after hibernate or hybrid-sleep
  logger -t zramit "post-$2"
  if [ "$2" = "hibernate" ] || [ "$2" = "hybrid-sleep" ];then
    "$_path"/zramit-script.sh init
  fi
  # friendly clear swapfiles if exist
  # just regroup a lot of read in a small time just to save other reads
  # _swapfiles=$(grep -v "zram" /proc/swaps |grep "file" |awk '{print $1}' |sed -e ':a;N;$!ba;s/\n/ /g')
  # echo "nice -19 swapoff -v $_swapfiles && swapon -d -v $_swapfiles" | at now + 3 minutes
fi
