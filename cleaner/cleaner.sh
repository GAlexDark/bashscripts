#!/bin/bash

schedulerLogsDir="/logs/scheduler"
dagProcessorManagerLogsDir="/logs/dag_processor_manager"
#dagProcessorManagerLogsDir="/var/log/mysql"

fileLog="/var/log/cleaner_info.log"
isDebug=0
olderThan="+31"

echo "$(date +%Y-%m-%d-%H-%M-%S) Start cleaning" >> "$fileLog"

if [ -n "$1" ]
then
    if [ "$1" = "--Debug" ]
    then
        echo "Debug mode enabled." >> "$fileLog"
        isDebug=1
    else
        echo "Unknown argument." >> "$fileLog"
    fi
fi

# ref: https://askubuntu.com/a/30157/8698
if ! [ "$( id -u )" = 0 ]
then
  echo -e "This script must run with the Root privileges!\nThe script terminated.\n$(date +%Y-%m-%d-%H-%M-%S) End cleaning\n"  >> "$fileLog"
  #exit 1
else
    echo "The script runs with the Root privileges." >> "$fileLog"
fi

#----------------------------------------------------------------------------
# Remove scheduler logs in their folders for pattern
removeByNamePattern () {
  local pattern

  #create pattern
  pattern=$(date --date="1 month ago" +"%Y-%m-*")
  if [ -z "$pattern" ]
  then
    echo -e "Wrong pattern. The script terminated.\n$(date +%Y-%m-%d-%H-%M-%S) End cleaning\n"  >> "$fileLog"
    exit 1
  fi
  if [ "$isDebug" -eq 1 ]
  then
    echo "The pattern for deleted directories: $pattern" >> "$fileLog"
  fi
  #remove files and directories from pattern
  find "$schedulerLogsDir" -maxdepth 1 -type d -iname "$pattern" -exec rm -rf {} \; >> "$fileLog" 2>&1
}
#----------------------------------------------------------------------------
# {
#  echo "Remove scheduler logs in their folders older than $olderThan days"
#  find "$schedulerLogsDir" -maxdepth 1 -type d -mtime "$olderThan" -exec rm -rf {} \;
# } >> $fileLog 2>&1
echo "Remove scheduler logs in their folders for pattern." >> "$fileLog"
removeByNamePattern
#----------------------------------------------------------------------------
{
  echo "Remove DAG Processor manager log files"
  find "$dagProcessorManagerLogsDir" -type f -iname '*.log.*' -mtime "$olderThan" -exec rm -rf {} \;
} >> "$fileLog" 2>&1
#----------------------------------------------------------------------------
echo -e "$(date +%Y-%m-%d-%H-%M-%S) End cleaning\n" >> "$fileLog"
exit 0