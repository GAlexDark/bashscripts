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

echo "Uninstall all old nginx packages"
apt remove --purge nginx
ret=$?
if [ $ret -ne 0 ] && [ $ret -ne 100 ]; then
  echo "Failed to uninstall nginx packages. Please uninstall manually and run the script again."
  exit 1
fi

echo "Install the prerequisites"
apt update && apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to install prerequisites. Please install manually and run the script again."
  exit 1
fi

echo "Import an official nginx signing key"
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

echo "Verify that the downloaded file contains the proper key"
gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

echo "Add the Mainline repository to Apt sources:"
# shellcheck source=/dev/null
echo \
  "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/ubuntu \
  $(. "$OSreleaseFile" && echo "$VERSION_CODENAME") nginx" | \
  sudo tee /etc/apt/sources.list.d/nginx.list > /dev/null

echo "Set up repository pinning to prefer our packages over distribution-provided ones"
echo \
  -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
  | sudo tee /etc/apt/preferences.d/99nginx

echo "Install the latest mainline nginx version"
apt update && apt install -y nginx
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to install nginx packages. Please install manually and run the script again."
  exit 1
fi

exit 0