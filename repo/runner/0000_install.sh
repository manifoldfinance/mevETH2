#!/usr/bin/env bash

set -eo pipefail



export DEBIAN_FRONTEND=noninteractive


sudo apt-get update  -qq
sudo apt-get upgrade -y -qq
sudo apt update -qq
sudo apt-get upgrade -qq --skip-keypress --checkall


sudo apt-get install -y -qq libsnappy-dev libc6-dev libc6 apt-transport-https

sleep 1


sudo apt-get update && apt-get install -y -qq --no-install-suggests --no-install-recommends \
        cmake \
        curl \
        libbz2-dev \
        libgmp-dev \
        build-essential \
        dpkg-sig \
        libcap-dev \
        libc6-dev \
        libgmp-dev \
        libbz2-dev \
        libreadline-dev \
        libsecp256k1-dev \
        libssl-dev \
        software-properties-common \
        libsnappy-dev libc6-dev libc6 apt-transport-https;

sudo apt update
sudo apt-get update

sudo apt-get install -y java-common build-essential software-properties-common zip -qq

##################################
### CONFIGURE NETWORK & TIMING ###

sudo sh -c 'echo "* hard nofile 100000" >> /etc/security/limits.conf'
sudo sh -c 'echo "* soft nofile 100000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root hard nofile 100000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root soft nofile 100000" >> /etc/security/limits.conf'
sleep 1

echo "==> Configuring NTP  "
# configure ntp
sudo apt update
sudo apt-get --assume-yes install ntp || true

sudo sed -i '/^server/d' /etc/ntp.conf
sudo tee -a /etc/ntp.conf << EOF
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
EOF
sleep 1

sudo systemctl restart ntp &> /dev/null || true
sudo systemctl restart ntpd &> /dev/null || true
sudo service ntp restart &> /dev/null || true
sudo service ntpd restart &> /dev/null || true
sudo restart ntp &> /dev/null || true
sudo restart ntpd &> /dev/null || true
ntpq -p

sudo sh -c 'echo "* hard nofile 64000" >> /etc/security/limits.conf'
sudo sh -c 'echo "* soft nofile 64000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root hard nofile 64000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root soft nofile 64000" >> /etc/security/limits.conf'

sudo apt-get update  -qq
sudo apt update -qq
sudo apt-get upgrade
sudo apt-get install -y apt-transport-https zip lzip -qq
sudo apt update
sudo apt-get update

sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w net.core.rmem_max=2500000
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# @param somaxconn should be >65536
sysctl net.core.somaxconn

echo "net.core.somaxconn=65536" >> /etc/sysctl.conf
sysctl -p



#---------------------------------#
# Install System Build Req.
#---------------------------------#

sudo apt-get update  -qq
sudo apt install lzip -y -qq
sudo sysctl -w vm.max_map_count=262144