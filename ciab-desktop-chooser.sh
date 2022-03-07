#!/bin/bash

INSTALL_DIR=/opt/ciab

CMD="install sed tasksel"
sudo apt-get -y ${CMD}

echo
echo
echo "====={ CIAB Desktop Environment Chooser }======================================================================="
echo
echo " Enter the Number of the Desktop Environment you want to install in CIAB."
echo
echo

PS3=' Please enter the Number for your choice of Desktop Environment to install... '
echo


LIST="KDE LXDE GNOME MATE XFCE BUDGIE CINNAMON"

select OPT in $LIST
do

if [ $OPT = "KDE" ] &> /dev/null
then
echo
echo "---------------------------------"
echo "You chose the Kubuntu KDE Desktop"
echo
CMD="tasksel install kde-standard"

# Create a flag file to indicate MATE was chosen for the Desktop Environment
# So when we install XRDP we will know whether we need to patch the
# /usr/share/applications/caja.desktop

sudo DEBIAN_FRONTEND=noninteractive apt install -y kubuntu-desktop
touch $INSTALL_DIR/fix-kde.flag
break

# was - elif [ $OPT = "LXDE" ] &> /dev/null
elif [ $OPT = "LXDE" ] &> /dev/null
then
echo
echo "----------------------------------"
echo "You chose the Lubuntu LXDE Desktop"
echo
CMD="tasksel install lubuntu-desktop"
break

elif [ $OPT = "GNOME" ] &> /dev/null
then
echo
echo "----------------------------------"
echo "You chose the Ubuntu Gnome Desktop"
echo
CMD="tasksel install ubuntu-desktop"
break

elif [ $OPT = "MATE" ] &> /dev/null
then
echo
echo "---------------------------------"
echo "You chose the Ubuntu MATE Desktop"
echo
CMD="tasksel install ubuntu-mate-desktop"

# Create a flag file to indicate MATE was chosen for the Desktop Environment
# So when we install XRDP we will know whether we need to patch the
# /usr/share/applications/caja.desktop

touch $INSTALL_DIR/fix-mate.flag
break


elif [ $OPT = "XFCE" ] &> /dev/null
then
echo
echo "----------------------------------"
echo "You chose the Xubuntu XFCE Desktop"
echo

CMD="tasksel install xubuntu-desktop"
break

elif [ $OPT = "BUDGIE" ] &> /dev/null
then
echo
echo "-----------------------------------"
echo "You chose the Ubuntu Budgie Desktop"
echo

CMD="tasksel install ubuntu-budgie-desktop"

# create a flag file to indicate BUDGIE was chosen for the Desktop Environment
# So when we install XRDP we will know whether we need to patch /etc/xrdp/startwm.sh
# See - CIAB Installation PDF in Errata section at the end.
#
# in some cases a "bypass.flag" file is created and is tested for later to
# see if the script should bypass installing a desktop.

touch ${INSTALL_DIR}/fix-budgie.flag
break


elif [ $OPT = "CINNAMON" ] &> /dev/null
then
echo
echo "----------------------------------"
echo "You chose the Cinnamon Desktop"
echo

touch ${INSTALL_DIR}/bypass.flag

sudo apt install -y cinnamon-desktop-environment
break


fi

done
#END

#=========================================================================================================
# There are several Desktop Environment that were not installed by tasksel but
# by using apt-get install

if [ -f ${INSTALL_DIR}/bypass.flag ]; then
	# if the bypass.flg file exists  the Selected Desktop was already installed
	# so just delete the flag file

	rm ${INSTALL_DIR}/bypass.flag

else
	echo
	echo
	echo "Installing the Chosen Desktop"
	echo
	echo

	sudo ${CMD}
	CMD="set-default graphical.target"
	sudo systemctl ${CND} > /dev/null
fi

#=========================================================================================================
# If either MATE or Budgie was selected for the CIAB LXD Desktop Container.
# each has a slight patches that need to be done for those Desktops to work correctly.
#=========================================================================================================

#
# For the MATE Desktop install we need a fix-up to the "/usr/share/applications/caja.desktop file"
#

# Check If the MATE Desktop was selected and installed and changed the caja.desktop file

FILE=${INSTALL_DIR}/fix-mate.flag
if [ -f $FILE ]; then
        sudo sed -i 's+caja$+caja --force-desktop+g' /usr/share/applications/caja.desktop
	sudo rm $FILE
fi

sudo apt-get autoremove -y





