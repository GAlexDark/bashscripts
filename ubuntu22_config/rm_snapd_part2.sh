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
  . $OSreleaseFile
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

echo "Remove snapd packages"
apt autoremove -y --purge snapd
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to remove snapd packages. Please remove manually and run the script again."
  exit 1
fi

echo "Remove snapd files and folders"
rm -rf /var/cache/snapd/
rm -rf /var/snap
rm -rf /var/lib/snapd

exit 0
