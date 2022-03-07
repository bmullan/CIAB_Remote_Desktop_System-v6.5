#!/bin/bash


clear

INSTALL_DIR="/opt/ciab"

#==================================================================================================================================
# ciab-pre-install.sh
#
# Purpuse:
#
# If the User/Installer doesn't already have LXD installed then this script will install it for them.
#==================================================================================================================================

echo
echo
echo "===={ BEGIN }================================================================================================================"
echo
echo "NOTE:  This script should NOT be executed as SUDO or ROOT .. but as your 'normal' UserID"
echo
echo "Checking if this script was axecuted as either Root or Sudo ... if it was then it will exit and you can try again."

echo
echo
if [ $(id -u) = 0 ]; then echo "Do NOT run this script SUDO or ROOT... Please re-run with your Normal UserID !"; exit 1 ; fi
echo
echo

echo
echo "==============================================================================================================================="
echo " Uninstall any pre-installed LXD and reinstall and re-init using an LXD Init Preseed Yaml config file so answers are all" 
echo " automated."
echo
echo
echo

sudo apt-get update && sudo apt-get upgrade -y

cd $INSTALL_DIR

LXD_EXISTS="/var/snap/lxd"

if [ -d $LXD_EXISTS ]
then
    echo "LXD is already installed so skipping installation of SNAP LXD."
else
    sudo apt-get purge lxd
    sudo apt-get install snapd
    sudo snap remove lxd
    sudo snap install lxd
fi

#====================================================================================================================================
# the following will use SED to substitute a password entered by the Installer for using LXD over the Internet
# for the "default' string "ciab-lxd-password" check the ciab-lxd-preseed.yaml

while true
   do
     clear
     echo
     echo "======================================================="
     echo
     read -s -p "Enter a Password for using LXD over the Network: " lxd_pwd
     echo
     read -s -p "Confirm the Password: " pwd_confirmation
     echo
     [ "$lxd_pwd" = "$pwd_confirmation" ] && break
     echo "Passwords don't match... try again!"
     echo
   done

sudo sed -i 's/ciab-lxd-password /$lxd_pwd/' $INSTALL_DIR/ciab-lxd-init-preseed.yaml
echo

echo
echo " Using the $INSTALL_DIR/ciab-lxd-init-preseed.yaml file for automating LXD INIT... "
echo

sudo lxd init --preseed < $INSTALL_DIR/ciab-lxd-init-preseed.yaml


#====================================================================================================================================
# Adding the Installer's UserID to the LXD group to enable use of lxc cli

sudo adduser $USER lxd

newgrp lxd

echo
echo "==============================================================================================================================="
echo echo 
echo " Next.. Please execute:"
echo
echo "                  ciab-install.sh"
echo
echo

exit




