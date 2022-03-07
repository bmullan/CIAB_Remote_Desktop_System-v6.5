#!/bin/bash


#=====================================================================================================================================
#
# NOTE:  This script should NOT be executed as SUDO or ROOT .. but as your 'normal' UserID
#

echo
echo
if [ $(id -u) = 0 ]; then echo "Do *NOT* run this script SUDO or ROOT... please run as your normal UserID !"; exit 1 ; fi
echo
echo


INSTALL_DIR="/opt/ciab"

cd $INSTALL_DIR

sudo apt-get update && sudo apt-get upgrade -y

clear
echo
echo
echo "====={ Create a Guacmole based CIAB Gateway }==================================================================================="
echo
echo " This Script is run inside the earlier created LXD container called \"ciab-gtwy\" and it will install a Dockerized version of"
echo " Apache\'s Guacamole, Tomcat9, NGINX, PostgreSQL will be installed \"nested\" in the LXD \"ciab-gtwy\" container."
echo
echo " When finished you will need to login to Guacamole from a Web Browser and configure a New Guacamole \"Connection\""
echo " and a new Guacmamole \"User\" account for in order to access any configured Desktops."
echo
echo " Wehn you create your Guacamole \"User\" account you give yourself  all System \"rights/privileges.\" "
echo " Remember to edit the \"guacadmin\" account and change the \"guacadmin\" password to something Secure other than its default."
echo "================================================================================================================================"
echo
echo


sudo apt-get install git unzip -y

cd $INSTALL_DIR

echo
echo
echo "================================================================================================================================"
echo
echo " Installing Docker on the Host Server/VM..."
echo
echo "================================================================================================================================"
echo

${INSTALL_DIR}/install-docker.sh

echo
echo
echo "================================================================================================================================"
echo " Retrieve the github code for the Dockerized version of Guacamole that we will use..."
echo
echo

cd $INSTALL_DIR

git clone "https://github.com/boschkundendienst/guacamole-docker-compose.git"

cd guacamole-docker-compose

sudo ./prepare.sh

sudo docker-compose up -d

#=====================================================================================================================================
# Change Permissions for the following directories:
#
#    $INSTALL_DIR/guacamole-docker-compose/drive to 777
#
# This is to enable CIAB/Guacamole to support a Virtual Drive Redirection to the CIAB User's Remote Desktop.
#
# This enables file transfer to/from the User's Local machine and the CIAB Remote Desktop.
#
#    $INSTALL_DIR/guacamole-docker-compose/record to 777
#
# This is to eable CIAB/Guacamole support for Audio Recording transfers to/from the User's Local machine and the CIAB Remote Desktop
#
# NOTE:
#       The names "drive" and "record" is declared in the dockerized guacamole's .YML file.
#       You are free to change them but then change the following also
#=====================================================================================================================================

sudo chmod -R 777 $INSTALL_DIR/guacamole-docker-compose/drive
sudo chmod -R 777 $INSTALL_DIR/guacamole-docker-compose/record

#=====================================================================================================================================
# Open Port 8443 for Docker use
#=====================================================================================================================================

sudo ufw allow 8443

echo
echo
echo
echo
echo
echo
echo "================================================================================================================================"
echo " The installation of the Dockerized Guacamole should now be complete..."
echo
echo " You should be able to point a Web Browser at:"
echo
echo "                  https://ip-of-server"
echo
echo " Default \"login/password\" for Guacamole is:   guacadmin/guacadmin"
echo
echo " To access CIAB Guacamole and configure \"Connections\" and \"Users\" for CIAB Remote Desktop running in ciab-cn1 LXD container"
echo





