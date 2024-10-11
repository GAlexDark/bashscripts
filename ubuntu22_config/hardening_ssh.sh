#!/bin/bash

# Copyrigth (C) Oleksii Gaienko, 2024

# ref: https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-18-04-ru
# ref: https://www.sshaudit.com/hardening_guides.html#ubuntu_22_04_lts
# ref: CIS Ubuntu Linux 22.04 LTS Benchmark v1.0.0 - 08-30-2022, Chapter 5.2 Configure SSH Server
# ref: https://github.com/decalage2/awesome-security-hardening?tab=readme-ov-file#ssh
# ref: DAT-NT-007-EN/ANSSI/SDE/NP - August 17, 2015
# ref: https://linux-audit.com/audit-and-harden-your-ssh-configuration/
# ref: https://blog.stribik.technology/2015/01/04/secure-secure-shell.html

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

sshConfig="/etc/ssh/sshd_config"
sshConfigBak=$sshConfig".bak"
if [ -f "$sshConfig" ]; then
  if ! cp -f $sshConfig $sshConfigBak
  then
    echo "Failed to create backup file"
    exit 1
  fi
  if ! sed -i "s/^X11Forwarding.*/X11Forwarding no/" $sshConfig
  then
    echo "Failed to change $sshConfig settings."
    if ! cp -f $sshConfigBak $sshConfig
    then
      echo "Failed to restore backup file"
      exit 1
    fi
    exit 1
  fi
  if ! sed -i "/^Subsystem/s/^/#/" $sshConfig
  then
    echo "Failed to change $sshConfig settings."
    if ! cp -f $sshConfigBak $sshConfig
    then
      echo "Failed to restore backup file"
      exit 1
    fi
    exit 1
  fi
fi
customSshd="/etc/ssh/sshd_config.d/sshd_hardening.conf"
if [ -f "$customSshd" ]; then
  rm -f "$customSshd"
fi

currentDir=$PWD
groups_file=.sshd_groups
allowGroup=""
denyGroup=""
if [ -f "$currentDir/$groups_file" ]; then
  echo "The sshd_groups file was found"
  # shellcheck source=/dev/null
  . "$currentDir/$groups_file"
  if [ -n "$SSH_ALLOW_GROUP" ]; then
    allowGroup="AllowGroups "$SSH_ALLOW_GROUP
  fi
  if [ -n "$SSH_DENY_GROUP" ]; then
    denyGroup="DenyGroups "$SSH_DENY_GROUP
  fi
fi

#ssh_config
#ForwardX11Trusted no

cat <<EOF >"$customSshd"
Protocol 2
Port 22
DebianBanner no
# Logging:
LogLevel INFO
SyslogFacility AUTH

PrintLastLog yes
PermitUserEnvironment no
MaxAuthTries 4
MaxStartups 10:30:60
MaxSessions 10
# Authentication:
LoginGraceTime 60
PermitRootLogin no
StrictModes yes

clientaliveinterval 15
PermitEmptyPasswords no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
IgnoreRhosts yes
HostbasedAuthentication no

# Privilege Separation is turned on for security
UsePrivilegeSeparation yes

# Access Groups:
${allowGroup}
${denyGroup}

#Enable the RSA and ED25519 keys
HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com
# hardening guide.
KexAlgorithms \
sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,\
diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256

Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com

HostKeyAlgorithms \
sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,\
sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256

CASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256

GSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-

HostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,\
ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,\
rsa-sha2-256

PubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,\
rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256
EOF

if [ ! -f "$customSshd" ]; then
  echo -e "Error! The file sshd_hardening.conf wasn't created.\nRestoring $sshConfig file."
  if ! cp -f "$sshConfigBak" $sshConfig
  then
    echo "Failed to restore backup file"
    exit 1
  fi
  exit 1
fi

d=$(date "+%Y%m%d")
backupDir=$currentDir/"backup_$d"
echo "$backupDir"
mkdir -pv "$backupDir"
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to create backup directory"
  exit 1
fi

cp -f "/etc/ssh/ssh_host_"* "$backupDir"
ret=$?
if [ $ret -ne 0 ]; then
  echo "Failed to copy files to the backup directory"
  exit 1
fi

echo "Re-generate the RSA and ED25519 keys"
rm -f "/etc/ssh/ssh_host_"*
if ! ssh-keygen -t rsa -b 4096 -f "/etc/ssh/ssh_host_rsa_key" -N ""
then
  echo "Failed to execute ssh-keygen."
  exit 1
fi
if ! ssh-keygen -t ed25519 -f "/etc/ssh/ssh_host_ed25519_key" -N ""
then
  echo "Failed to execute ssh-keygen."
  exit 1
fi

echo "Remove small Diffie-Hellman moduli"
if ! cp -f "/etc/ssh/moduli" "$backupDir/"
then
  echo "Failed to create backup"
  exit 1
fi
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.new
if ! mv /etc/ssh/moduli.new /etc/ssh/moduli
then
  echo "Failed to create moduli file"
  exit 1
fi

if ! chown root:root "$sshConfig" "$customSshd"
then
  echo "Failed to execute chown."
  exit 1
fi
if ! chmod og-rwx "$sshConfig" "$customSshd"
then
  echo "Failed to execute chmod."
  exit 1
fi

find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chmod u-x,go-wx {} \;
find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chown root:root {} \;

service sshd reload
exit 0
