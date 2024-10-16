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

services=("snapd.apparmor.service" "snapd.seeded.service" "snapd.socket" "snapd.mounts-pre.target" "snapd.mounts.target")
echo "Stop snapd services"
systemctl stop "${services[@]}"
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to systemctl stop. Please stop snapd services manually and run the script again."
  exit 1
fi
echo "Disable snapd services"
systemctl disable "${services[@]}"
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to systemctl disable. Please disable snapd services manually and run the script again."
  exit 1
fi
echo "Mask snapd services"
systemctl mask "${services[@]}"
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to systemctl mask. Please mask snapd services manually and run the script again."
  exit 1
fi

echo "Rebooting..."
shutdown -r now

exit 0