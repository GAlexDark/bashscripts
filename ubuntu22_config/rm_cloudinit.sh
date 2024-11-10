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

echo "Removing cloud-init"
touch /etc/cloud/cloud-init.disabled
export  DEBIAN_FRONTEND=noninteractive
dpkg-reconfigure cloud-init
dpkg-reconfigure cloud-init
apt-get purge --assume-yes cloud-ini*
ret=$?
if [ $ret -ne 0 ] && [ $ret -ne 100 ]; then
  echo "Failed to uninstall cloud-init. Please uninstall manually and run the script again."
  echo "Return code: $ret"
  exit 1
else
  echo "The cloud-init was removed"
fi

echo "Remove cloud-init files and folders"
rm -rf /etc/cloud/
rm -rf /var/lib/cloud/

echo "Rebooting..."
shutdown -r now

exit 0
