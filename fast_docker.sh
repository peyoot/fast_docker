#!/bin/bash
##########################################################################
############################  peyoot@hotmail.com #########################


if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1 
fi 



_() { 
set -euo pipefail
# Declare an array so that we can capture the original arguments.
declare -a ORIGINAL_ARGS 



# Define I/O helper functions.
error() {
  if [ $# != 0 ]; then
    echo -en '\e[0;31m' >&2
    echo "$@" | (fold -s || cat) >&2
    echo -en '\e[0m' >&2
  fi
}

fail() {
  local error_code="$1"
  shift
  if [ "${SHOW_FAILURE_MSG:-yes}" = "yes" ] ; then
    echo "*** INSTALLATION FAILED ***" >&2
    echo ""
  fi
  error "$@"
  echo "" >&2
  exit 1
}




prompt() {
  local VALUE
  # Hack: We read from FD 3 because when reading the script from a pipe, FD 0 is the script, not
  #   the terminal. We checked above that FD 1 (stdout) is in fact a terminal and then dup it to FD 3, thus we can input from FD 3 here. We use "bold", rather than any particular color, to 
  # maximize readability. See #2037.
  echo -en '\e[1m' >&3
  echo -n "$1 [$2]" >&3
  echo -en '\e[0m ' >&3
  read -u 3 VALUE
  if [ -z "$VALUE" ]; then
    VALUE=$2
  fi
  echo "$VALUE"
}
prompt-numeric() {
  local NUMERIC_REGEX="^[0-9]+$"
  while true; do
    local VALUE=$(prompt "$@")
    if ! [[ "$VALUE" =~ $NUMERIC_REGEX ]] ; then
      echo "You entered '$VALUE'. Please enter a number." >&3
    else
      echo "$VALUE"
      return
    fi
  done
}
prompt-yesno() {
  while true; do
    local VALUE=$(prompt "$@")
    case $VALUE in
      y | Y | yes | YES | Yes )
        return 0
        ;;
      n | N | no | NO | No )
        return 1
        ;;
    esac
    echo "*** Please answer \"yes\" or \"no\"."
  done
}

########## custom functions ###############

get_speed() {
  docker rmi -f $TEST_IMG >>/dev/null 2>&1
  START_TIME=$(date +%s)
  docker pull $TEST_IMG >>/dev/null 2>&1
  END_TIME=$(date +%s)
  COST_TIME=$[ $END_TIME-$START_TIME ]
#  COST_TIME=$(($END_TIME-$START_TIME))
}



####Check if run as root#######
ROOTUID="0"
if [ "$(id -u)" -ne "$ROOTUID" ] ; then
  echo "This script must be executed with root privileges. try with sudo or root account"
  exit 1
fi



# define global variables check if parent folder is ready
TEST_IMG=registry:2
BEST_MIRROR=""

if [ -e /lib/systemd/system/docker.service.bak ] && [ -e /var/log/fast_docker.log ]; then
  echo "It seems you've run the scipt before. Your original docker configure backup file is in place"
  echo "Script will directly checkout fastest docker mirror and configre docker.service for you"
else
  if [ -e /lib/systemd/system/docker.service.bak ]; then
    if prompt-yesno "docker systemd configure backup file already exist, would you like to overwrite it? " "no"; then
        cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
    else
        echo "Scripts will backup your original docker.service to /tmp"
        cp /lib/systemd/system/docker.service /tmp/docker.service.bak
    fi
  else
    cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
  fi
fi

if [ ! -e /var/log/fast_docker.log ]; then
  echo "fast_docker installed" >> /var/log/fast_docker.log
fi

#check default one's speed
#get_speed
#set azure china is default  mirror in case default one is block
sed -i "/--containerd=/cExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --registry-mirror=https://dockerhub.azk8s.cn" /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker
sleep 1
get_speed

COST_TIME_BEST=$COST_TIME

# try mirror, if fast, update COST_TIME_LAST and mirror_url
# please use your own url if you got one
mirrors=("https://registry.docker-cn.com"
    "https://mirror.ccs.tencentyun.com"
    "http://f1361db2.m.daocloud.io"
    "http://hub-mirror.c.163.com"
    "https://docker.mirrors.ustc.edu.cn"
  )
## adding more mirrors by using your own aliyun mirror url instead.


for(( i=0;i<${#mirrors[@]};i++)) do
  #${#mirrors[@]}获取数组长度用于循环
  echo "now try ${mirrors[i]}";
  get_speed
  echo "Pulling test image took $(($COST_TIME/60))min $(($COST_TIME%60))s"
  if [ $COST_TIME -lt $COST_TIME_BEST ]; then
      echo "found better mirror...."
      COST_TIME_BEST=$COST_TIME
      BEST_MIRROR="${mirrors[i]}"
      echo "Now best mirror is $BEST_MIRROR"
      sed -i "/--containerd=/cExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --registry-mirror=$BEST_MIRROR" /lib/systemd/system/docker.service
      sleep 1
      systemctl daemon-reload
      systemctl restart docker
  fi
done;

#if [ "" = "$BEST_MIRROR" ]; then
#  echo "no faster mirror found"
#else    
#  echo "Best mirror is ${BEST_MIRROR}"
#  sed -i "/--containerd=/cExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --registry-mirror=$BEST_MIRROR" /lib/systemd/system/docker.service
#fi


}

_ "$0" "$@"
