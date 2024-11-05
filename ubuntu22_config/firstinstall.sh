#!/bin/bash

# Copyrigth (C) Oleksii Gaienko, 2024

# Checking to run as root user
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as the root user."
  exit 1
fi

# Checking the Ubuntu version
OSreleaseFile="/etc/os-release"
if [ -f "$OSreleaseFile" ]; then
  # shellcheck source=/dev/null
  . "$OSreleaseFile"
  if [ "$ID" = "ubuntu" ] && [ "$(echo "$VERSION_ID" | cut -d. -f1)" -ge 22 ]; then
    echo "You are using Ubuntu $VERSION_ID. Continue executing the script."
  else
    echo "Warning: Your Linux version ($PRETTY_NAME) is different from the one on which the script was tested."
    echo "Some settings may not work as expected."
  fi
else
  echo "The operating system version could not be determined."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt update
ret=$?
if [ $ret -ne 0 ] && [ $ret -ne 100 ]; then
  echo "Failed to install apt-utils or dialog. Please install manually and run the script again."
  exit 1
fi

if ! apt upgrade -y
then
  echo "Failed to upgrade packeges. Please upgrade manually and run the script again."
  exit 1
fi

if ! apt install -y build-essential linux-headers-"$(uname -r)" eject iputils-ping bind9-dnsutils mc fdisk rng-tools-debian
then
  echo "Failed to install basic packeges. Please install manually and run the script again."
  exit 1
fi

exit 0
