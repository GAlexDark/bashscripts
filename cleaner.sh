#!/bin/bash

#---------------------------------------
# input arguments
# $1 - Enable Debug mode: --Debug
#---------------------------------------

schedulerLogsDir="/logs/scheduler"
dagProcessorManagerLogsDir="/logs/dag_processor_manager"

fileLog="/var/log/cleaner_info.log"
isDebug=0
olderThan="+31"

echo "$(date +%Y-%m-%d-%H-%M-%S) Start cleaning" >> $fileLog

if [ -n "$1" ]
then
    if [ "$1" = "--Debug" ]
    then
        echo "Debug mode is enabled." >> $fileLog
        isDebug=1
    else
        echo "Unknown argument." >> $fileLog
    fi
fi

# ref: https://askubuntu.com/a/30157/8698
if ! [ "$( id -u )" = 0 ]
then
  echo -e "This script must run with the Root privileges!\nThe script terminated.\n$(date +%Y-%m-%d-%H-%M-%S) End cleaning\n"  >> $fileLog
  exit 1
else
    echo "The script runs with the Root privileges." >> $fileLog
fi

#----------------------------------------------------------------------------
# Remove scheduler logs in their folders for pattern
removeByNamePattern () {
  local december
  december=12
  local january
  january=1
  local currentYear
  currentYear="$(date +%Y)"
  local currentMonth
  currentMonth="$(date +%m)"
  local pattern
  local removedYear
  local removedMonth

  if [ "$isDebug" -eq 1 ]
  then
    echo "Current year: $currentYear" >> $fileLog
    echo "Current month: $currentMonth" >> $fileLog
  fi

  if [ "$currentMonth" -eq "$january" ]
  then
    removedYear=$(( currentYear-1 ))
    removedMonth=$december
  else
    removedYear="$currentYear"
    removedMonth=$(( currentMonth-1 ))
  fi
  if [ "$isDebug" -eq 1 ]
  then
    echo "Removed Year: $removedYear" >> $fileLog
    echo "Removed Month: $removedMonth" >> $fileLog
  fi
  #create pattern
  pattern=$(printf "%d-%.2d-*" "$removedYear" "$removedMonth")
  if [ "$isDebug" -eq 1 ]
  then
    echo "The pattern for deleted directories: $pattern" >> $fileLog
  fi
  #remove files and directories from pattern
  find "$schedulerLogsDir" -maxdepth 1 -type d -iname "$pattern" -exec rm -rf {} \; >> $fileLog 2>&1
}
#----------------------------------------------------------------------------
# {
#  echo "Remove scheduler logs in their folders older than $olderThan days"
#  find "$schedulerLogsDir" -maxdepth 1 -type d -mtime "$olderThan" -exec rm -rf {} \;
# } >> $fileLog 2>&1
echo "Remove scheduler logs in their folders for pattern." >> $fileLog 2>&1
removeByNamePattern
#----------------------------------------------------------------------------
{
  echo "Remove DAG Processor manager log files"
  find "$dagProcessorManagerLogsDir" -type f -iname '*.log.*' -mtime "$olderThan" -exec rm -rf {} \;
} >> $fileLog 2>&1
#----------------------------------------------------------------------------
echo -e "$(date +%Y-%m-%d-%H-%M-%S) End cleaning\n" >> $fileLog
exit 0