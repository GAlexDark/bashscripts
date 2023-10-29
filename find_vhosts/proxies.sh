#!/bin/bash

source 'user_agents.sh'
source 'parsers.sh'

#SETTINGS_FILE=find_vhosts.cnf
#CURRENT_DIR=$PWD

#if [ -f $CURRENT_DIR/$SETTINGS_FILE ]; then
#  echo "Settings file exists!"
#else
#  echo "Settings file not find in current directory!"
#  exit
#fi
#source $CURRENT_DIR/$SETTINGS_FILE

#if [ "$CONNECT_TIMEOUT" != "" ]; then
#  g_connect_timeout=( --connect-timeout "$CONNECT_TIMEOUT" )
#else
#  g_connect_timeout=( --connect-timeout 20 )
#fi

#case ${SOCKS_PROXY,,} in
#4) g_socks_type="socks4://" #"--socks4"
#  ;;
#4a) g_socks_type="socks4a://" #"--socks4a"
#  ;;
#*) g_socks_type="socks5://" #"--socks5"
#  ;;
#esac

get_current_ip () {
  local header_user_agent
  local myip

  header_user_agent=$( get_random_ua )
  myip=$( curl -L -k -A "$header_user_agent" --no-progress-meter "$IP_CHECKER" 2>&1 )
  if [[ "$retVal" == *"curl:"* ]]; then
    echo "Error connect to checker: $myip"
    exit
  else
    parse_current_ip_response "$myip"
  fi
}

check_current_proxy () {
# $1 -- proxy ip
# $2 -- url for check proxy ip
# $3 -- current ip ( using get_current_ip )

  if [ "$CONNECT_TIMEOUT" != "" ]; then
    g_connect_timeout=( --connect-timeout "$CONNECT_TIMEOUT" )
  else
    g_connect_timeout=( --connect-timeout 20 )
  fi

  local header_user_agent
  local retVal
  local ip
  local proxy_item

  proxy_item="$g_socks_type$1/"  
  header_user_agent=$( get_random_ua )

  retVal=$( curl -L -k -A "$header_user_agent" "${g_connect_timeout[@]}" --no-progress-meter --proxy "$proxy_item" "$2" 2>&1 ) #"$g_socks_type" "$1" "$2" 2>&1 )
  if [[ "$retVal" == *"curl:"* ]]; then
    echo "proxy not work: $retVal"
  else
    ip=$( parse_current_ip_response "$retVal" )
    if [ "$3" = "$ip" ]; then
      echo "proxy is not secure" #: $retVal"
    else
      echo "proxy is secure" #: $retVal"
    fi
  fi
}

#proxy_ip=$( check_current_proxy "127.0.0.1:42636" "$IP_CHECKER" get_current_ip )
#echo "Tested proxy IP: $proxy_ip"

load_proxy_list () {
  index=0
  while read -r line; do
    g_work_proxies[index]="$line"
    (( index+=1 ))
  done < "$g_work_proxy_list"
}

get_random_proxy () {
local RANGE
local rnd

  RANGE=${#g_work_proxies[*]}
  #echo "Array items count: $RANGE"
  rnd=$RANDOM
  #echo "Current RANDOM: $rnd"
  (( rnd %= RANGE ))
  #echo "Random number less than $RANGE: $rnd"
  echo "${g_work_proxies[$rnd]}"
}

export -f get_current_ip
export -f check_current_proxy
export -f load_proxy_list
export -f get_random_proxy
