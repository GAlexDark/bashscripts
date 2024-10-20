#!/bin/bash
# shellcheck disable=SC2317
schedulerLogsDir="/logs/scheduler"
dagProcessorManagerLogsDir="/logs/dag_processor_manager"

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
removeByDate() {  
  declare -aI buf=()
  while IFS='' read -r line; do buf+=("$line"); done < <(find "$dagProcessorManagerLogsDir" -type f -iname '*.log.*' -mtime "$olderThan")
  while IFS='' read -r line; do buf+=("$line"); done < <(find "$dagProcessorManagerLogsDir" -type f -iname '*.log.*' -atime "$olderThan")

  declare -aI fileNames=()
  while IFS='' read -r line; do fileNames+=("$line"); done < <(for item in "${buf[@]}"; do echo "${item}"; done | sort -u)
  unset buf

  if (( ${#fileNames[*]} > 0 )); then
    if [ "$isDebug" -eq 1 ]
    then
      {
        echo "The files to be deleted:"
        for item in "${fileNames[@]}"; do
          echo "${item}"
        done
      } >> "$fileLog"
    fi
    for item in "${fileNames[@]}"; do
      rm -f "${item}" >> "$fileLog" 2>&1
    done
  else
    echo "Nothing to remove."
  fi
  unset fileNames
}

#----------------------------------------------------------------------------
echo "Delete scheduler logs in their folders for pattern." >> "$fileLog"
removeByNamePattern
#----------------------------------------------------------------------------
echo "Delete DAG Processor manager log files." >> "$fileLog"
removeByDate
#----------------------------------------------------------------------------
endTimeStamp="$(date +%Y-%m-%d-%H-%M-%S) End cleaning"
{
  echo "$endTimeStamp"
  echo
} >> "$fileLog"
exit 0