#!/bin/sh

# search for the script and assign path
if [ -f "/usr/local/sbin/zramit-script.sh" ];then
  _path="/usr/local/sbin"
else
  if [ -f "/usr/sbin/zramit-script.sh" ];then
    _path="/usr/sbin"
  else
    if [ -f "/usr/local/bin/zramit-script.sh" ];then
      _path="/usr/local/bin"
    else
      _path="/usr/bin"
    fi
  fi
fi

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
  _swapfiles=$(grep -v "zram" /proc/swaps |grep "file" |awk '{print $1}' |sed -e ':a;N;$!ba;s/\n/ /g')
  # friendly clear swapfiles if exist
    echo "nice -19 swapoff -v $_swapfiles && swapon -d -v $_swapfiles" | at now + 3 minutes
fi
