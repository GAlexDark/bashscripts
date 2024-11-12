#!/bin/bash

# Copyrigth (C) Oleksii Gaienko, 2024

# Checking to run as root user
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as the root user."
  exit 1
fi

mode=${TERM}
if [ "$mode" != "linux" ]; then
  echo -e "This script must run in the console ONLY.\n"
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
  gcllValue+=" netcfg\/do_not_use_netplan=true "
  gcll="GRUB_CMDLINE_LINUX="\"$gcllValue\"
  echo "$gcll"
  sed -i "s/^GRUB_CMDLINE_LINUX=.*/${gcll}/" $grubFile
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

echo "Installing packages"
apt update && apt install -y ifupdown net-tools resolvconf
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to install ifupdown, net-tools and resolvconf. Please install manually and run the script again."
  exit 1
fi

echo "Creating interfaces list"
echo -e "# The loopback network interface\nauto lo\niface lo inet loopback" >> /etc/network/interfaces.d/loopback

interfacesFile="/etc/network/interfaces"
if [ ! -f "$interfacesFile" ]; then
  echo -e "The interfaces file creation\n"
  echo -e "# interfaces(5) file used by ifup(8) and ifdown(8)\n# Include files from /etc/network/interfaces.d:\nsource /etc/network/interfaces.d/*\n" >> $interfacesFile
fi
niName=$(ls /sys/class/net | grep enp)
for nic in "${niName[@]}"; do
  echo -e "\nauto ${nic}\niface ${nic} inet dhcp" >> $interfacesFile
done

echo "Remove link to the resolv.conf"
unlink /etc/resolv.conf

services=("systemd-networkd.socket" "systemd-networkd" "networkd-dispatcher" "systemd-networkd-wait-online" "systemd-resolved")
echo "Stop netplan services"
systemctl stop "${services[@]}"
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to systemctl stop. Please update grub manually and run the script again."
  exit 1
fi
echo "Disable netplan services"
systemctl disable "${services[@]}"
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to systemctl disable. Please update grub manually and run the script again."
  exit 1
fi
echo "Mask netplan services"
systemctl mask "${services[@]}"
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to systemctl mask. Please update grub manually and run the script again."
  exit 1
fi
echo "Remove netplan packages"
apt --assume-yes purge nplan netplan.io
ret=$?
if [ $ret -ne 0 ] && [ $ret -ne 100 ]; then
  echo "Failed to remove netplan packages. Please remove manually and run the script again."
  echo "Return code: $ret"
  exit 1
else
  echo "The netplan packages was removed"
fi
echo "Remove all unused packages"
apt autoremove -y
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to remove netplan packages. Please remove manually and run the script again."
  exit 1
fi

echo "Remove netplan files and folders"
rm -rf /etc/netplan/

echo "Rebooting..."
shutdown -r now

exit 0
