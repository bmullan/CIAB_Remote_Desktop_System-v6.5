#!/bin/bash


# NOTE:  This script should NOT be executed as SUDO or ROOT .. but as a normal UserID

# Check if user is root or sudo ... if so... then exit and tell user.

echo
echo
if [ $(id -u) = 0 ]; then
        echo
        echo
        echo "                        Do NOT run this script as SUDO or ROOT..."
        echo
        echo "                           Please re-run as your normal UserID !"; exit 1 ;
        echo
        echo
        echo
fi




clear
echo
echo
echo
echo "====={ Welcome to the CIAB Installer for Desktop Containers }==========================================================="
echo
echo " PURPOSE:"
echo
echo "   Create an LXD Desktop Container w/ a user selected Desktop Environment (DE) installed in the "
echo "   container."
echo
echo "   Also, installed is xRDP using the latest NeutrinoLabs  xRDP source code."
echo "   xRDP will be built & installed on Desktop Container with audio redirection supported in xRDP connections and"
echo "   configured with a 'ciab-share' folder on the  Users Container 'Desktop'.   In that folder is the Users"
echo "   'Host' 'Home' directory mapped as a 'virtual drive' to which you can drag/drop files to/from the Host and"
echo "   the Desktop Container"
echo
echo " During this installation the following Desktop Environment (DE) choices are available to select:"
echo
echo "     - KDE Plasma"
echo "     - MATE"
echo "     - Gnome"
echo "     - LXDE"
echo "     - Budgie"
echo "     - XFCE"
echo "     - Cinnamon"
echo
echo " This script will create an initial User Account '${USER}' in the new Container Desktop using the 'Host' UserID of"
echo " the installer."
echo
echo " The Installer will also be prompted enter responses for:"
echo
echo "   1)  a Name for the new LXD Desktop Container"
echo "   2)  normal adduser command  prompts for input password, name of user, save y/n etc."
echo
echo " This script will then give that new UserID 'sudo' privileges in the container."
echo
echo "========================================================================================================================"
echo
echo

read -p "Press any key when ready to begin... "


#===============
#===={BEGIN}====
#===============

USER_NAME=${USER}

# Set the Installation variable INSTALL_DIR to the Directory this script will be executed from

INSTALL_DIR=/opt/ciab

# ID the latest version (v1.3 of the C-Energy xRDP installer script (see below for URL)

XRDP_SCRIPT="ciab-xrdp-installer"

clear
echo
echo "========================================================================================================================"
echo
echo " Enter a name for your new LXD Desktop Container:  "
echo
echo " Hint:  if you want to create a MATE LXD Desktop then maybe name the new LXD Desktop Container 'Mate-Desktop' "
echo "        and the other LXD Desktop Containers might be 'KDE-Desktop' 'Gnome-Desktop' etc."
echo
echo

read -p " Enter the name for your new LXD Desktop Container:  " CN_NAME

echo
echo
echo "========================================================================================================================"
echo " Creating the LXD Desktop Container using the name ${CN_NAME} provided above."
echo
echo

lxc launch ubuntu:focal ${CN_NAME}

sleep 8

echo
echo
echo "====={ Append 'pulseaudio -k' command to /etc/skel/.profile }==========================================================="
echo
echo " Before we add any 'future' User Accounts to the LXD Desktop Container ${CN_NAME}, we will append 1 command to the"
echo " Containers system '/etc/skel/.profile'.   That command is 'pulseaudio -k'. "
echo
echo " When any future User Accounts are created in the ${CN_NAME} LXD Desktop Container the '.profile' created in their"
echo " Home directory will be copied from the Container system  '/etc/skel/.profile' skeleton template."
echo
echo " The Purpose of the 'pulseaudio -k' will be to kill ${USER_NAME} ${CN_NAME} 'Pulseaudio' and automatically restart it"
echo " whenever ${USER_NAME} logs back into the ${CN_NAME} LXD Desktop Container!"
echo
echo "========================================================================================================================"
echo
echo
read -p " Press any key to Continue.. "
echo
echo
echo


#=========================================================================================================================
# retrieve the Desktop Containers "/etc/skel/.profile" file so
# this script can append 1 line to it then
# the script will use "lxc file push" to put the  file
# back to replace the ${CN_NAME} /etc/skel/.profile file

lxc file pull ${CN_NAME}/etc/skel/.profile ./${CN_NAME}.profile

sudo echo 'pulseaudio -k' >> ./${CN_NAME}.profile

lxc file push ./${CN_NAME}.profile ${CN_NAME}/etc/skel/.profile
rm ./${CN_NAME}.profile


# ========================================================================================================================
# add the Installer's UserID account in the Desktop Container

CMD="sudo adduser ${USER_NAME}"
lxc exec ${CN_NAME} -- $CMD

# lxc exec ${CN_NAME} -- sudo ${CMD}

# add a User account for the Installing USER_NAME

echo
echo
echo
echo "===={ Creating your User Account in the LXD Desktop Container ${CN_NAME} }==============================================="
echo

CMD="sudo adduser ${USER_NAME}"
lxc exec ${CN_NAME} -- ${CMD}

# make yourself member of adm and sudo groups so you can use sudo in the container

CMD="sudo adduser ${USER_NAME} adm"
lxc exec ${CN_NAME} -- ${CMD}

CMD="sudo adduser ${USER_NAME} sudo"
lxc exec ${CN_NAME} -- ${CMD}

echo
echo
echo
echo "====={ Update/Upgrade the ${CN_NAME} Container }==============================================="
echo

CMD="apt update"
lxc exec ${CN_NAME} -- sudo ${CMD}

CMD="apt upgrade -y"
lxc exec ${CN_NAME} -- sudo ${CMD}

# install unzip

CMD="apt install unzip -y"
lxc exec ${CN_NAME} -- sudo ${CMD}

#=============================================================================================================
# Create a work directory... /opt/ciab/, make its owner/group your userID and set file
# access privileges, change to that directory and download the C-Energy xrdp install script v1.3

echo
echo
echo
echo "====={ Create a 'work' directory ${INSTALL_DIR} in your LXD Desktop Container ${CN_NAME} }================================"
echo

CMD="mkdir ${INSTALL_DIR}"
lxc exec ${CN_NAME} -- sudo ${CMD}

CMD="chmod -R 766 ${INSTALL_DIR}"
lxc exec ${CN_NAME} -- sudo ${CMD}

CMD="chown -R ${USER_NAME}:${USER_NAME} ${INSTALL_DIR}"
lxc exec ${CN_NAME} -- sudo ${CMD}


echo
echo
echo
echo "====={ Run the 'ciab-desktop-chooser.sh' that will let ${USER} choose which Desktop Environment to install }============="
echo
sleep 3

FILE="ciab-desktop-chooser.sh"
lxc file push ${INSTALL_DIR}/${FILE} ${CN_NAME}/${INSTALL_DIR}/

CMD="chmod 766 ${INSTALL_DIR}/${FILE}"
lxc exec ${CN_NAME} -- sudo ${CMD}

CMD="ciab-desktop-chooser.sh"
CMD="chown ${USER_NAME}:${USER_NAME} ${INSTALL_DIR}/${CMD}"
lxc exec ${CN_NAME} -- sudo ${CMD}


CMD="ciab-desktop-chooser.sh"
lxc exec ${CN_NAME} -- sudo ${INSTALL_DIR}/${CMD}

CMD="file push ${INSTALL_DIR}/ciab-login.bmp ${CN_NAME}${INSTALL_DIR}/"
lxc ${CMD}


#================================================================================================================
# After the chosen Desktop is installed we need to install xRDP in the ${CN_NAME} container.
#
# Install the latest xRDP from source code and enable audio support using  C-Energys great script ... its easy!
# The reason we do this is that the xrdp in the Ubuntu repositories is a fairly old version.
#
# reference:   https://c-nergy.be/blog/?p=16817Steps
#================================================================================================================

echo
echo
echo
echo "========================================================================================================="
echo "===| Next execute 'ciab-xrdp-installer.sh' which is a CIAB modified version of C-Energys Script      ===|"
echo "===| 'xrdp-installer-1.3.sh'.  It gets placed in the ${CN_NAME} Desktop container                  ===|"
echo "===|                                                                                                 ===|"
echo "===| This uses NeutrinoLabs xRDP source code compiled w/Audio Redirection support and then installed ===|"
echo "========================================================================================================="
echo
echo
read -p "Press any key to Continue... "
echo
echo

# Put the CIAB modified version of the C-Energy xRDP install script v3 into the Desktop Container directory ${INSTALL_DIR}

XRDP_SCRIPT="ciab-xrdp-installer.sh"
lxc file push ${INSTALL_DIR}/${XRDP_SCRIPT} ${CN_NAME}/${INSTALL_DIR}/


#=================================================================================================================
# Make "${FILE}" owner and group "${USER_NAME}"

CMD="chown -R ${USER_NAME}:${USER_NAME} ${INSTALL_DIR}/"
lxc exec ${CN_NAME} -- sudo ${CMD}

# Make ${FILE} executable in the ${CN_NAME} CIAB Desktop Container

CMD="chmod -R +x ${INSTALL_DIR}/"
lxc exec ${CN_NAME} -- sudo ${CMD}

echo
echo
echo "===================================================================================================================="
echo " Execute the Script ${XRDP_SCRIPT} with 3 command options"
echo
echo " -c means the script should download the latest XRDP source code from NeutrinoLabs, compile & install it"
echo " -l means the script will create a custom login menu using the ciab-desktop.bmp file"
echo " -s means the script should add sound/audio support to XRDP"
echo
echo
sleep 4

CMD="${INSTALL_DIR}/${XRDP_SCRIPT} -c -l -s"
lxc exec ${CN_NAME} -- sudo --login --user ${USER_NAME} ${CMD}


#===================================================================================================================
# If the Budgie Desktop was selected for the CIAB LXD Desktop Container "flag" file named "fix-budgie.flag".
# There is a command that needs to be inserted into "/etc/xrdp/startwm.sh".
#
#===================================================================================================================

FILE=${INSTALL_DIR}/fix-budgie.flag
if [ -f $FILE ]; then

        # Replace the 2nd occurrence of "wm_start" in/etc/xrdp/startwm.sh
        # with "budgie-desktop"

        CMD="sed -i 's+wm_start+budgie-desktop+g' /etc/xrdp/startwm.sh"
	lxc exec ${CN_NAME} -- sudo ${CMD}

        CMD="sed -i 's+budgie-desktop()+wm_start()+g' /etc/xrdp/startwm.sh"
	lxc exec ${CN_NAME} -- sudo ${CMD}

        # clean up by deleting our our fix-budgie "flag" file
        sudo rm $FILE
fi


#===================================================================================================================
# Open Port 3389 in the Desktop Container, RDP uses Port 3389

CMD="ufw allow 3389"
lxc exec ${CN_NAME} -- sudo ${CMD}

# Now you have your chosen Desktop and xrdp installed in your Container so back on the LXD Host install freerdp2-x11

sudo apt install freerdp2-x11 -y


echo
echo
echo
echo "========================================================================================================================"
echo " Use the 'lxc list' command to find the IP address of your ${CN_NAME} container by extracting the IPV4 address Column "
echo " entry of the 'lxc list' output for the ${CN_NAME} LXD Desktop Container."
echo
echo
sleep 3


CN_IP=$(lxc list ${CN_NAME} -c 4 | awk '!/IPV4/{ if ( $2 != "" ) print $2}' )


#==========================================================================================================================
# Next step is to create a "ciab-share" directory 'in your Host' 'Home' Directory where you can drag/drop files
# to/from the Container/Host easily.
#
# NOTE: CIAB by default will create a directory called "/home/${USER_NAME}/ciab-share" for this purpose.
#
#==========================================================================================================================

SHARED_FOLDER="/home/${USER_NAME}/ciab-share"

echo
echo
echo
echo "===================================================================================================================="
echo " Next step is to create the ${SHARED_FOLDER} 'share' directory in '/home/${USER_NAME}/' directory"
echo " where you can drag/drop files to/from the Container/Host easily."
echo "===================================================================================================================="
echo
echo
sleep 2


#==========================================================================================================================
# Create a small script to do the execution of freerdp to access your ${CN_NAME} Desktop container this script calls
# "${CN_NAME}.sh" and creates this script in ${USER_NAME}'s HOME directory
#
# When executed the User signing in will be prompted for their Login User ID and Password.
#
# Upon successfully entering those the User will be presented with their LXD Container Desktop
#==========================================================================================================================


echo
echo
echo
echo "===================================================================================================================="
echo " Create a 'launch' Script in /home/${USER_NAME} called '${CN_NAME}.sh'. "
echo
echo " When you execute '/home/${USER_NAME}/${CN_NAME}.sh' it will launch that LXD Container Desktop for you."
echo
echo " The Script ${CN_NAME}.sh will use 'freerdp' to bring up a ${CN_NAME} Desktop Login screen where you"
echo " need to enter your ${CN_NAME} Desktop Login ID and Password."
echo
echo " The Script, when executed will 'share' your Host \/home/$USER_NAME}/ directory on ${CN_NAME} Desktop"
echo " Container inside of a directory named '/home/${USER_NAME}/Desktop/ciab-share' "
echo
echo " The Script will use the 'lxc list' command to find the IP address of your ${CN_NAME} LXD Container Desktop"
echo " container by extracting the IPV4 address Column entry of the 'lxc list' entry."
echo
echo " Lastly, to make the '${CN_NAME}.sh' Script executable from anywhere it is copied to '/usr/bin/' also. "
echo
read -p " Press any key to Continue..."
echo
echo


#================

cat > /home/${USER_NAME}/${CN_NAME}.sh <<END
#!/bin/bash
xfreerdp /cert-ignore +gfx /rfx /rfx-mode:video /video /bpp:32 /dynamic-resolution /home-drive +clipboard /sound:sys:pulse,format:1,quality:high,rate:44100,latency:50 /v:$CN_IP
END

# for some reason the above puts a "|" symbol on the last line of the script so the following removes that symbol

sed -i 's+|++g' /home/${USER_NAME}/${CN_NAME}.sh


#================

#==========================================================================================================================
# End of script ${CN_NAME}.sh creation
#==========================================================================================================================

echo
echo "======================================================================================================================="
echo " Make ${CN_NAME}.sh executable"
echo

sudo chmod +x /home/${USER_NAME}/${CN_NAME}.sh

echo
echo "======================================================================================================================="
echo " Make the script accessible easily from anywhere on your Host."

FILE="/home/${USER_NAME}/${CN_NAME}.sh"

sudo cp "${FILE}" /usr/bin/

#=======================================================================================================================
# Test if the "ciab-gtwy" container already exists by using the "lxc info" command
# if it does NOT return an Error then "ciab-gtwy" was already create and configured previously.
#
# If "ciab-gtwy" does not exist then it is created and the Oockerizedd Guacamole installed "nested" inside it.

lxc info ciab-gtwy > /dev/null
if [ $? -eq 0 ]
then
	echo
	echo " ciab-gtwy container already exists... "
	echo
else
	echo
	echo
	echo
	echo "======================================================================================================================="
	echo " CIAB can create the additional capability of accessing 'local' or 'remote' Container Desktops using any HTML5"
	echo " Web Browser and Guacamole installed on this Server/VM/Cloud-Instance."
	echo
	read -p " Do you wish to add this capability? (y/n): " -n 1 -r

	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
		echo
		echo
		echo " The CIAB Guacamole container will NOT be created..."
		echo
		echo
	else
		echo
		echo
		echo " Creating an LXD container called 'ciab-gtwy' and enable 'nesting' "
		echo
		echo

		CN="ciab-gtwy"

		lxc launch ubuntu:focal $CN -c security.nesting=true
		sleep 8

		# ========================================================================================================================
		# add the Installer's UserID account in the ciab-gtwy container

		echo
		echo
		echo
		echo "===={ Creating your User Account in the LXD 'ciab-gtwy' container }==============================================="
		echo

		CMD="adduser ${USER_NAME}"
		lxc exec ${CN} -- sudo ${CMD}

		# make yourself member of adm and sudo groups so you can use sudo in the container

		CMD="adduser ${USER_NAME} adm"
		lxc exec ${CN} -- sudo ${CMD}

		CMD="adduser ${USER_NAME} sudo"
		lxc exec ${CN} -- sudo ${CMD}

		# create /opt/ciab install directory in the new ciab-gtwy container

		CMD="mkdir ${INSTALL_DIR}"
		lxc exec ${CN} -- sudo ${CMD}

		CMD="chown -R ${USER_NAME}:${USER_NAME} ${INSTALL_DIR}"
		lxc exec ${CN} -- sudo ${CMD}

		CMD="chmod -R 766 ${INSTALL_DIR}"
		lxc exec ${CN} -- sudo ${CMD}

		echo
		echo
		echo
		echo "====={ Push the mk-ciab-gtwy.sh script to the $CN container }==============================================="
		echo

		FILE=mk-ciab-gtwy.sh
		CMD="${INSTALL_DIR}/${FILE} ${CN}/${INSTALL_DIR}/"
		lxc file push ${CMD}

		FILE=install-docker.sh
		CMD="${INSTALL_DIR}/${FILE} ${CN}/${INSTALL_DIR}/"
		lxc file push ${CMD}

		CMD="chmod -R 766 ${INSTALL_DIR}"
		lxc exec ${CN} -- sudo ${CMD}

		CMD="chown -R ${USER_NAME}:${USER_NAME} ${INSTALL_DIR}"
		lxc exec ${CN} -- sudo ${CMD}

		# Finally install the CIAB Dockerized Guacamole "nested" in the ${CN} LXD Container

		CMD=${INSTALL_DIR}/mk-ciab-gtwy.sh
		lxc exec ${CN} -- sudo --login --user ${USER_NAME} ${CMD}

		# Finally, since Docker uses port 8443 we open that in the ${CN} LXD Container
		CMD="ufw allow 8443"
		lxc exec ${CN} -- sudo ${CMD}

		echo
		echo
		echo "=============================================================================================================================="
		echo " Use LXD to forward incoming Port 443 (re https) to the ciab-gtwy container."
		echo " proxy port 443 on host to ciab-gtwy so a web browser trying to connect via port 443 (ie https/tls)"
		echo
		echo " The CIAB Dockerized Guacamole is configured to listen on Port 8443 so to simplify things and just let the CIAB Users"
		echo " point to the Host Server/VMs IP using HTTPS (re Port 443) and let  LXD Proxy Device redirect that to "
		echo " Port 8443 in the ciab-gtwy container... which is where the Dockerized Guacamole is running as a 'nested' container"
		echo
		lxc config device add ciab-gtwy proxyport443 proxy listen=tcp:0.0.0.0:443 connect=tcp:127.0.0.1:8443

	fi
fi

echo
echo
echo
echo "=========================================================================================================================="
echo
echo " You are now ready to access the new Container Desktop."
echo
echo " The Creation and Configuration of the '${CN_NAME}' LXD Desktop Container also created '${SHARED_FOLDER}' in"
echo " /home/${USER_NAME}."
echo
echo " A Launcher Script '/home/${USER_NAME}/${CN_NAME}.sh' was also created to make it easy to connect and login to the ${CN_NAME}"
echo " LXD Container Desktop.   '${CN_NAME}.sh' will use freerdp to connect to your ${CN_NAME} Desktop."
echo
echo " NOTE"
echo "        The initial LOGIN & PASSWORD are the Login & Password you specified during creation of the ${CN_NAME} LXD Desktop"
echo
echo "        If you configured everything correctly your Container Desktop should pop up and you can start working."
echo
echo "=========================================================================================================================="
echo
echo
echo
echo
echo


#===================================================================================================================
# If the Budgie Desktop was selected for the CIAB LXD Desktop Container "flag" file named "fix-budgie.flag".
# There is a command that needs to be inserted into "/etc/xrdp/startwm.sh".
#===================================================================================================================

FILE=${INSTALL_DIR}/fix-budgie.flag
if [ -f $FILE ]; then

        # Replace the 2nd occurrence of "wm_start" in/etc/xrdp/startwm.sh
        # with "budgie-desktop"

        sudo sed -i 's+wm_start+budgie-desktop+g' /etc/xrdp/startwm.sh

        sudo sed -i 's+budgie-desktop()+wm_start()+g' /etc/xrdp/startwm.sh

        # clean up by deleting our our fix-budgie "flag" file
        sudo rm $FILE
fi

