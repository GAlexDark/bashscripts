#!/bin/bash

schedulerLogsDir="/logs/scheduler"
#dagProcessorManagerLogsDir="/logs/dag_processor_manager"
dagProcessorManagerLogsDir="/var/log/nginx"

fileLog="/var/log/cleaner_info.log"
isDebug=0
olderThan="+31"

startTimeStamp="$(date +%Y-%m-%d-%H-%M-%S) Start cleaning"

echo "$startTimeStamp" >> "$fileLog"

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
  echo -e "This script must run with the Root privileges!\nThe script terminated.\n$(date +%Y-%m-%d-%H-%M-%S) End cleaning\n"
  exit 1
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
    {
      echo "The pattern for deleted directories: $pattern"
      echo "The directories to be deleted:"
      find "$schedulerLogsDir" -maxdepth 1 -type d -iname "$pattern" -print
    }  >> "$fileLog" 2>&1
  fi
  #remove files and directories from pattern
  find "$schedulerLogsDir" -maxdepth 1 -type d -iname "$pattern" -exec rm -rf {} \; >> "$fileLog" 2>&1
}
#----------------------------------------------------------------------------
echo "Delete scheduler logs in their folders for pattern." >> "$fileLog"
removeByNamePattern
#----------------------------------------------------------------------------
{
  echo "Delete DAG Processor manager log files."
  if [ "$isDebug" -eq 1 ]
  then
    echo "The files to be deleted:"
    find "$dagProcessorManagerLogsDir" -type f -iname '*.log.*' -mtime "$olderThan" -print
  fi
  find "$dagProcessorManagerLogsDir" -type f -iname '*.log.*' -mtime "$olderThan" -exec rm -f {} \;
} >> "$fileLog" 2>&1
# mtime - modify, atime - access, ctime -birth (can be empty)
#----------------------------------------------------------------------------
endTimeStamp="$(date +%Y-%m-%d-%H-%M-%S) End cleaning\n"
echo "$endTimeStamp" >> "$fileLog"
exit 0