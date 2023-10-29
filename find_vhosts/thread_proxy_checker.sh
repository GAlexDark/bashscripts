#!/bin/bash

# $1 -- proxy IP
# $2 -- IP_CHECKER
# $3 -- current IP
# $4 -- proto

source 'proxies.sh'
source 'sqlite.sh'

proxy_check () {
  local timestamp
  local retVal

  timestamp=$( date +%s%3N ) 
  retVal=$( check_current_proxy "$1" "$2" "$3" )
  timestamp=$(( $( date +%s%3N ) - timestamp ))
  if [[ "$retVal" == *"not work"* ]]; then
    insert_error_info "$1" "$retVal" "$4"
  else
    insert_proxy_info "$1" "$timestamp" "$retVal" "$4"
  fi

  echo "Checking $1 done"
}

proxy_check "$1" "$2" "$3" "$4"
exit 0