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

echo "Uninstall all old docker packages"
apt remove --purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
ret=$?
if [ $ret -ne 0 ] && [ $ret -ne 100 ]; then
  echo "Failed to uninstall docker packages. Please uninstall manually and run the script again."
  exit 1
fi

echo "Remove Docker's data"
rm -rf /var/lib/docker
rm -rf /var/lib/containerd

echo "Add Docker's official GPG key"
apt update && apt install -y ca-certificates curl software-properties-common apt-transport-https
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to install GPG key. Please install manually and run the script again."
  exit 1
fi
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "Add the repository to Apt sources:"
# shellcheck source=/dev/null
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. "$OSreleaseFile" && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Install the latest Docker version"
apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to install Docker packages. Please install manually and run the script again."
  exit 1
fi

echo "Check versions"
docker --version
docker compose version