#!/bin/bash

sqlite_settings="PRAGMA busy_timeout=120000; PRAGMA journal_mode = OFF;"
req="select proxy from proxy pr order by pr.response_time asc;"

init () {
  if [ ! -f "$g_db_name" ]; then
    #sqlite3 "$g_db_name" "PRAGMA busy_timeout=20000; PRAGMA synchronous = '0'; PRAGMA journal_mode = 'OFF';" 
    sqlite3 "$g_db_name" "CREATE TABLE error (id INTEGER, proxy TEXT, description TEXT, proto TEXT, PRIMARY KEY(id AUTOINCREMENT));"
    sqlite3 "$g_db_name" "CREATE TABLE proxy (id INTEGER, proxy TEXT, response_time INTEGER, description TEXT, proto TEXT, PRIMARY KEY(id AUTOINCREMENT));"
  else
    echo "DB exists"
  fi
}

init_vhost_db () {
  if [ ! -f "$g_hostdb_name" ]; then
    sqlite3 "$g_hostdb_name" "CREATE TABLE vhost_scan_info ( id INTEGER, timestamp TEXT, proxy TEXT, \
                          host TEXT, vhost TEXT, status_code INTEGER, server TEXT, location TEXT, date TEXT, expires TEXT, allow TEXT, cookie TEXT, \
                          content_type TEXT, strict_transport_security TEXT, referrer_policy TEXT, content_security_policy TEXT, \
                          x_content_type_options TEXT, x_xss_protection TEXT, x_frame_options TEXT, x_csrf_token TEXT, \
                          x_powered_by TEXT, x_powered_cms TEXT, x_forwarded_for TEXT, x_forwarded_host TEXT, x_request_id TEXT, www_authenticate TEXT, \
                          front_end_https TEXT, proto TEXT,is_name_resolved INTEGER, x_tracking_ref TEXT, x_execution_time TEXT, PRIMARY KEY(id AUTOINCREMENT));"
    sqlite3 "$g_hostdb_name" "CREATE TABLE error (id INTEGER, timestamp TEXT, proxy TEXT, host TEXT, vhost TEXT, description TEXT, proto TEXT, PRIMARY KEY(id AUTOINCREMENT));"
  else
    echo "DB exists"
  fi

}

insert_proxy_info () {
  sqlite3 -batch "$g_db_name" "$sqlite_settings""insert into proxy (proxy,response_time,description,proto) values ('$1','$2','$3','$4');" 1>/dev/null
}

insert_error_info () {
local str
  str="$2"
  str=${str//\'/\'\'}
  sqlite3 -batch "$g_db_name" "$sqlite_settings""insert into error (proxy,description,proto) values ('$1','${str}','$3');"  1>/dev/null
}

get_work_proxy_list () {
  sqlite3 "$g_db_name" "$req" > "$1" # -cmd ".mode column" 
}

insert_vhost_scan_info () {
  #echo "$g_hostdb_name"
  sqlite3 -batch "$g_hostdb_name" "$sqlite_settings""insert into vhost_scan_info (timestamp,proxy,host,vhost,status_code,server,location,date,expires,allow,cookie,content_type, \
                                strict_transport_security,referrer_policy,content_security_policy,x_content_type_options,x_xss_protection,x_frame_options, \
                                x_csrf_token,x_powered_by,x_powered_cms,x_forwarded_for,x_forwarded_host,x_request_id,www_authenticate,front_end_https,proto,is_name_resolved,
                                x_tracking_ref, x_execution_time) values (datetime('now','localtime'), \
                                        '$1','$2','$3','$4','$5','$6','$7','$8','$9','${10}','${11}','${12}','${13}','${14}','${15}','${16}','${17}', \
                                        '${18}','${19}','${20}','${21}','${22}','${23}','${24}','${25}','${26}','${27}','${28}','${29}')" 1>/dev/null

}

insert_vhost_error_info () {
local str
  str="$4"
  str=${str//\'/\'\'}
  sqlite3 -batch "$g_hostdb_name" "$sqlite_settings""insert into error (timestamp,proxy,host,vhost,description,proto) \
                                values (datetime('now','localtime'),'$1','$2','$3','${str}','$5');" 1>/dev/null
}

export -f init
export -f insert_proxy_info
export -f insert_error_info

export -f init_vhost_db

# https://www.outcoldman.com/en/archive/2017/07/19/dbhist/
# https://unix.stackexchange.com/questions/648286/can-the-words-in-these-bash-strings-efficiently-be-inserted-into-an-sqlite-table



