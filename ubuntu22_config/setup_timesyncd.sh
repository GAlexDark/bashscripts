#!/bin/bash

# Copyrigth (C) Oleksii Gaienko, 2024

if [ "$#" -ne 1 ]; then
  echo "The NTP IP-address or domain name is not set."
  exit 1
fi
ntpIp=$1
if [[ $ntpIp =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  echo "Checking IP-address"
  IFS="." read -r -a arr <<< "$ntpIp"
  if [[ ${arr[0]} -le 255 && ${arr[1]} -le 255 && ${arr[2]} -le 255 && ${arr[3]} -le 255 ]]; then
    echo "$ntpIp is correct IP-address"  
  else
    echo "$ntpIp is wrong IP-address"
    exit 1
  fi
else
  echo "Checking a possible domain name"
  validate="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"
  if [[ "$ntpIp" =~ $validate ]]; then
    ip=$(dig +short "$ntpIp")
    if [ ${#ip} -ne 0 ]; then
      echo "$ntpIp is correct domain name"
    else
     echo "$ntpIp is incorrect domain name"
     exit 1
    fi
  else
    echo "$ntpIp is not valid name."
    exit 1
  fi
fi

# Checking to run as root user
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as the root user."
    exit 1
fi

# Checking the Ubuntu version
OSreleaseFile="/etc/os-release"
if [[ -f $OSreleaseFile ]]; then
  # shellcheck source=/dev/null
  . "$OSreleaseFile"
  if [[ "$ID" == "ubuntu" && "$(echo "$VERSION_ID" | cut -d. -f1)" -ge 22 ]]; then
    echo "You are using Ubuntu $VERSION_ID. Continue executing the script."
  else
    echo "Warning: Your Linux version ($PRETTY_NAME) is different from the one on which the script was tested."
    echo "Some settings may not work as expected."
  fi
else
  echo "The operating system version could not be determined."
  exit 1
fi

echo "Uninstall NTP packages"
apt-get remove --purge ntp ntpstat
ret=$?
if [ $ret -ne 0 ] && [ $ret -ne 100 ]; then
  echo "Failed to uninstall NTP packages. Please uninstall manually and run the script again."
  exit 1
fi

echo "Remove all unused packages"
if ! apt-get autoremove -y; then
  echo "Failed to autoremove unused packages. Please remove manually and run the script again."
  exit 1
fi

echo "Setup time zone"
if ! timedatectl set-timezone Europe/Kyiv; then
  echo "Failed to set timezone. Please set timezone manually and run the script again."
  exit 1
fi
echo "Checking timezone"
ls -lh /etc/localtime
if ! timedatectl status; then
  echo "Failed to exec timedatectl."
  exit 1
fi

echo "Setup time synchronization"
timesyncdConfig="/etc/systemd/timesyncd.conf"
timesyncdConfigBak=$timesyncdConfig".bak"
if [[ -f $timesyncdConfig ]]; then
  cp -f $timesyncdConfig $timesyncdConfigBak
  sed -i "s/#NTP=/NTP=${ntpIp}/" $timesyncdConfig
else
  echo "Unable access to the timesyncd.conf file."
  exit 1
fi

echo "Activate systemd-timesyncd for time sync"
if ! timedatectl set-ntp true; then
  echo "Failed to activate systemd-timesyncd. Please activate systemd-timesyncd manually and run the script again."
  exit 1
fi

echo "Enable systemd-timesyncd service"
if ! systemctl enable --now systemd-timesyncd.service; then
  echo "Failed to enable systemd-timesyncd.service. Please enable systemd-timesyncd.service manually and run the script again."
  exit 1
fi

echo "Restart systemd-timesyncd service"
if ! systemctl restart systemd-timesyncd.service; then
  echo "Failed to restart systemd-timesyncd.service. Please restart systemd-timesyncd.service manually and run the script again."
  exit 1
fi

echo "Checking systemd-timesyncd service status"
if ! systemctl status systemd-timesyncd.service; then
  echo "Failed to get systemd-timesyncd.service status. Please get systemd-timesyncd.service status manually and run the script again."
  exit 1
fi

echo "Checking timesyncd status"
if ! timedatectl status; then
  echo "Failed to exec timedatectl."
  exit 1
fi

exit 0