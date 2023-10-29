#!/bin/bash

x="https://www.site.com:443/"
awk -F[/] '{print $3}' <<< "$x"

#exit 0

source 'sqlite.sh'

SETTINGS_FILE=find_vhosts.cnf
CURRENT_DIR=$PWD

req="select pr.proto, pr.proxy from proxy pr order by pr.response_time asc;"

if [ -f "$CURRENT_DIR/$SETTINGS_FILE" ]; then
  echo "Config file exists!"
else
  echo "Config file not find in the current directory!"
  exit
fi
source $CURRENT_DIR/$SETTINGS_FILE
# init db
if [ "$DB_NAME" != "" ]; then
  g_db_name="$CURRENT_DIR/$DB_NAME"
else
  echo "Database name not specified"
  exit
fi


sqlite3 "$g_db_name" "$req" > test_sqlite_result.txt # -cmd ".mode column" 
#retVal=$(sqlite3 "$g_db_name" "$req" )
while read -r line; do

  fieldA=$( awk -F[\|] '{print $1}' <<< "$line" )
  fieldB=$( awk -F[\|] '{print $2}' <<< "$line" )

  echo "proto A es ... ${fieldA}"
  echo "proxy B es ... ${fieldB}"

done < <(sqlite3 "$g_db_name" "$req" )
