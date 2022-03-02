#!/bin/bash

INSTALL_DIR="/opt/ciab"

cd $INSTALL_DIR

#======================================================================================================
#  CIAB v5  - setup-docker.sh - Install/Configure docker and docker-compose 
#======================================================================================================
#
# Notes: none yet
#


# ====================================================================================================================================
#
# NOTE:  This script should NOT be executed as SUDO or ROOT .. but as your 'normal' UserID
#

echo
echo
if [ $(id -u) = 0 ]; then echo "Do *NOT* run this script SUDO or ROOT... Please re-run as your Normal UserID !"; exit 1 ; fi
echo
echo


# Just to be sure let's Uninstall any previous Docker

sudo apt-get remove docker docker-engine docker.io containerd runc

# add the official Docker repository to our /etc/apt/sources.list

sudo apt-get update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y

echo
echo "================================================================================================================================"
echo " Adding Docker's GPG key and repository to the ciab-guac container's /etc/apt/sources.list.d/"
echo
echo

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "================================================================================================================================"
echo " Installing Docker into the ciab-guac container"
echo
echo " Note:  if you ever want to uninstall Docker just execute:"
echo
echo "      $ sudo apt-get purge docker-ce docker-ce-cli containerd.io"
echo
echo

sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io -y

echo "================================================================================================================================"
echo " Install docker-compose in the ciab-guac container and make it executable."
echo
echo " As of Oct 2021 the newest stable version is  1.29.2"
echo
echo

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo cp /usr/local/bin/docker-compose /usr/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo chmod +x /usr/bin/docker-compose

echo "================================================================================================================================"
echo " Adding your UserID to the "Docker" Group so you can execute Docker commands w/out sudo later"

sudo adduser $USER docker

echo "================================================================================================================================"
echo
echo "Docker and Docker-Compose should now be installed in the ciab-guac container..."
echo
echo







