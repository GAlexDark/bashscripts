#!/bin/bash

# $1 - filename with vhost -- /path/vhosts_full.list
# $2 - filename with host targets -- /path/domain.list
# $3 - domain -- domain.name
# $4 - result

#Import functions from files
source 'user_agents.sh'
source 'referers.sh'
source 'parsers.sh'
source 'proxies.sh'
source 'sqlite.sh'
source 'std_headers.sh'

SETTINGS_FILE=find_vhosts.cnf
CURRENT_DIR=$PWD

if [ -f "$CURRENT_DIR/$SETTINGS_FILE" ]; then
  echo "Settings file exists!"
else
  echo "Settings file not find in current directory!"
  exit
fi
source "$CURRENT_DIR/$SETTINGS_FILE"

case ${SOCKS_PROXY,,} in
4) g_socks_type="socks4://" #"--socks4"
  ;;
4a) g_socks_type="socks4a://" #"--socks4a"
  ;;
*) g_socks_type="socks5://" #"--socks5"
  ;;
esac
export g_socks_type

if [ "$WORK_PROXY_LIST" != "" ] && [ -f "$WORK_PROXY_LIST" ]; then
  g_work_proxy_list="$WORK_PROXY_LIST"
  g_work_proxies=()
else
  echo "Proxy list not exists"
  exit
fi
export g_work_proxy_list
export g_work_proxies
load_proxy_list

# init db
if [ "$VHOST_RESULT_DB" != "" ]; then
  g_hostdb_name="$CURRENT_DIR/$VHOST_RESULT_DB"
else
  echo "Database name not specified"
  exit
fi
export g_hostdb_name
init_vhost_db

if [ "$CONNECT_TIMEOUT" != "" ]; then
  connect_timeout=( --connect-timeout "$CONNECT_TIMEOUT" )
else
  connect_timeout=( --connect-timeout 20 )
fi

standard_headers=( -H "$header_accept" -H "$header_accept_language" -H "$header_accept_encoding" -H "$header_dnt" -H "$header_connection" \
                   -H "$header_upgrade_insecure_requests" -H "$header_sec_fetch_dest" -H "$header_sec_fetch_mode" -H "$header_sec_fetch_site" \
                   -H "$header_sec_fetch_user" -H "$header_sec_gpc" -H "$header_pragma" -H "$header_cache_control" )



#shopt -s extglob # Required to trim whitespace; see below

index=0
while read -r line; do
      vhost_array[$index]="$line"
      (( index+=1 ))
done < "$1"
index=0
while read -r line; do
      host_array[$index]="$line"
      (( index+=1 ))
done < "$2"

#while read -r vhost #host
#do
#    while read -r host #vhost
#    do
for ((i=0; i < ${#vhost_array[*]}; i++))
do
    for ((j=0; j < ${#host_array[*]}; j++))
    do
        { echo ""; echo " -= TARGET: ${host_array[j]} =- "; echo ""; } >> "$4"
        retVal=""
        dns=0
        proto="http"
        header_host=${vhost_array[$i]}.$3
        header_user_agent=$( get_random_ua )
        header_referer=$( get_random_referer "$header_host" )

        random_proxy=$( get_random_proxy )
        proxy_item="$g_socks_type$random_proxy/"
        
        url=$proto://${host_array[j]}
#        while [ "$g_status" -gt 300 ] && [ "$g_status" -lt 350 ]
#        do
          echo "Results for vhost : $header_host" >> "$4"

          retVal=$( curl -L -I -k --no-progress-meter --max-redirs 5 -H "Host: $header_host" "${standard_headers[@]}" -A "$header_user_agent" \
                 "${connect_timeout[@]}" -e "$header_referer" --proxy "$proxy_item" "$url" 2>&1)
          echo "$retVal" >> "$4"
          if [[ "$retVal" == *"curl:"* ]] && [[ "$retVal" != *"HTTP/"* ]]
          then
            echo "Error to connect to ${vhost_array[$i]}"
            insert_vhost_error_info "$random_proxy" "${host_array[j]}" "${vhost_array[$i]}" "$retVal" "$proto"
          else
            echo "Connect to ${vhost_array[$i]}"
            parse_response_headers "$retVal"
            if [[ "$g_curl_info" == *"Could not resolve host"* ]]; then
              dns=0
            fi
            g_csp=${g_csp//\'/\'\'}
            insert_vhost_scan_info "$random_proxy" "${host_array[j]}" "${vhost_array[$i]}" "$g_status" "$g_server" "$g_location" "$g_date" "$g_expires" "$g_allow" "$g_cookie" "$g_ct" \
                                "$g_sts" "$g_rp" "$g_csp" "$g_x_cto" "$g_x_xssp" "$g_x_frame_options" "$g_x_csrf_token" "$g_x_powered_by" "$g_x_powered_cms" \
                                "$g_x_forwarded_for" "$g_x_forwarded_host" "$g_x_request_id" "$g_www_auth" "$g_front_end_https" "$proto" "$dns" "$g_x_tracking_ref" \
                                "$g_x_execution_time"
          fi
#          url=$g_location
#          proto=$( get_proto_from_url "$url" )
#        done # while
    done # for j
done # for i

#    done < "$2" #"$1"
#done < "$1" #"$2"

exit 0

# ToDo: https://support-acquia.force.com/s/article/360005257154-Use-cURL-s-resolve-option-to-pin-a-request-to-an-IP-address
# https://www.joyfulbikeshedding.com/blog/2020-05-11-best-practices-when-using-curl-in-shell-scripts.html