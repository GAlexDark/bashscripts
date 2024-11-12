#!/bin/bash

# Copyrigth (C) Oleksii Gaienko, 2024

# Checking to run as root user
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as the root user."
  exit 1
fi

echo "Checking the Ubuntu version"
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

echo "Changing GRUB settings"
grubFile="/etc/default/grub"
grubBak=$grubFile".bak"
if [ -f "$grubFile" ]; then
  cp -f $grubFile $grubBak
  ret=$?
  if [ $ret -ne 0 ]; then
    echo "Failed to create backup file"
    exit 1
  fi
  # shellcheck source=/dev/null
  . "$grubFile"
  gcllValue=$GRUB_CMDLINE_LINUX
  gcllValue+=" ipv6.disable=1 "
  gcll="GRUB_CMDLINE_LINUX="\"$gcllValue\"
  echo "$gcll"
  sed -i "s|^GRUB_CMDLINE_LINUX=.*|${gcll}|" $grubFile
  ret=$?
  if [ $ret -ne 0 ]; then
    echo "Failed to change GRUB settings. Please change GRUB settings manually and run the script again."
    cp -f $grubBak $grubFile
    ret=$?
    if [ $ret -ne 0 ]; then
      echo "Failed to restore backup file"
      exit 1
    fi
    exit 1
  fi
else
    echo "Cannot access to the GRUB file."
    exit 1
fi

echo "Updating GRUB settings"
update-grub
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to update grub. Please update grub manually and run the script again."
  cp -f $grubBak $grubFile
  ret=$?
  if [ $ret -ne 0 ]; then
    echo "Failed to restore backup file"
    exit 1
  fi
  exit 1
fi

exit 0