#!/bin/bash

#source 'user_agents.sh'
#source 'parsers.sh'
source 'proxies.sh'
source 'sqlite.sh'

SETTINGS_FILE=find_vhosts.cnf
CURRENT_DIR=$PWD

if [ -f "$CURRENT_DIR/$SETTINGS_FILE" ]; then
  echo "Config file exists!"
else
  echo "Config file not find in the current directory!"
  exit
fi
source $CURRENT_DIR/$SETTINGS_FILE

if [ "$CONNECT_TIMEOUT" != "" ]; then
  g_connect_timeout=( --connect-timeout "$CONNECT_TIMEOUT" )
else
  g_connect_timeout=( --connect-timeout 20 )
fi
export g_connect_timeout

case ${SOCKS_PROXY,,} in
4) g_socks_type="socks4://" #"--socks4"
  ;;
4a) g_socks_type="socks4a://" #"--socks4a"
  ;;
*) g_socks_type="socks5://" #"--socks5"
  ;;
esac
export g_socks_type

if [ "$PROXY_FILE" != "" ] && [ -f "$PROXY_FILE" ]; then
  g_proxy_source="$PROXY_FILE"
else
  echo "Proxy list not exists"
  exit
fi

# init db
if [ "$DB_NAME" != "" ]; then
  g_db_name="$CURRENT_DIR/$DB_NAME"
else
  echo "Database name not specified"
  exit
fi
export g_db_name

init
#exit 0
myip=$( get_current_ip )
echo "My current IP: $myip"

#index=0
while read -r line; do
#    echo "Check proxy IP: $line"
#    timestamp=$( date +%s%3N ) 
#    retVal=$( check_current_proxy "$line" "$IP_CHECKER" "$myip" )
#    timestamp=$(( $( date +%s%3N ) - timestamp ))
#    if [[ "$retVal" == *"not work"* ]]; then
#      echo "$retVal"
#      insert_error_info "$line" "$retVal"
#    else
#      echo "Response time: $timestamp ms"
#      insert_proxy_info "$line" "$timestamp" "$retVal"
#      array[$index]="$line"
#      (( index+=1 ))
#    fi

    bash "$CURRENT_DIR/thread_proxy_checker.sh" "$line" "$IP_CHECKER" "$myip" "${g_socks_type/:\/\//}"  &
done < "$g_proxy_source"

#echo "Results:"

#for ((a=0; a < ${#array[*]}; a++))
#do
#    echo "$a: ${array[$a]}"
#done

wait
echo "Check proxy finished!"
echo ""
echo "Create reporting"
if [ "$WORK_PROXY_LIST" != "" ] && [ -f "$WORK_PROXY_LIST" ]; then
  report_file="$WORK_PROXY_LIST"
else
  echo "Proxy list not exists"
  exit
fi
rm -f "$report_file"
get_work_proxy_list "$report_file"

exit 0

# https://mnorin.com/parallelnoe-vypolnenie-v-bash.html