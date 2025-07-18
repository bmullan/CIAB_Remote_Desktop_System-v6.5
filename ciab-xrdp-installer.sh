#!/bin/bash

# NOTE:  This script should NOT be executed as SUDO or ROOT .. but as a normal UserID

# Check if user is root or sudo ... if so... then exit and tell user.

echo
echo
if [ $(id -u) = 0 ]; then
        echo
        echo
        echo "Do NOT run this script as SUDO or ROOT..."
        echo
        echo "Please re-run as your normal UserID !"; exit 1 ;
        echo
        echo
        echo
fi

USER_NAME=$USER

echo
echo
echo " ${USER_NAME} you are starting to install a CIAB Desktop LXD Container..."
echo
echo
sleep 3

## was - INSTALL_DIR=${PWD}

INSTALL_DIR=/opt/ciab

#####################################################################################################
# Script_Name : xrdp-installer-1.3.sh
# Description : Perform xRDP installation on Ubuntu 18.04,20.4,20.10,21.04 and perform
#               additional post configuration to improve end user experience
# Date : October 2021
# written by : Griffon
# WebSite :http://www.c-nergy.be - http://www.c-nergy.be/blog
# Version : 1.3
# History : 1.3   - Adding support for Ubuntu 21.10 (STR)
#                 - Code modification sound redirection using meson technology (ubuntu 21.10 only so far)
#                 - Adding code to copy config.h file which seems to be missing from xrdp-pulseaudio modules
#                 - Adding support for Debian (10 and 11) (Best Effort)
#                 - Commenting out installation of Gnome Tweaks. Tweaks is not installed anymore by default
#                 - Added Rules to Detect Budgie-Desktop and postConfig settings
#                 - Added support for Pop!_0S (Best Effort !!!)
#                 - Code Changes to detect Desktop Interface in use
#                 - Reworked code for xrdp removal option
#                 - Improved Std vs Custom installation detection process
#                 - Added support for Different Desktop Interfaces (More testing needed)
#                 - General Code structure re-worked to add more OS version and Desktop interface support
#                 - Fixed Minor Bug(s)
#         : 1.2.3 - Adding support for Ubuntu 21.04
#                 - Removing Support for Ubuntu 16.04.x (End Standard Support)
#                 - Delete xrdp and xorgxrdp folder when remove option selected
#                 - Review remove function to detect hwe package U18.04
#                 - Review, Optimize, Cleanup Code
#         : 1.2.2 - Changing Ubuntu repository from be.archive.ubuntu.com to archive.ubuntu.com
#                 - Bug Fixing - /etc/xrdp/xrdp-installer-check.log not deleted when remove option
#                   selected in the script - Force Deletion (Thanks to Hiero for this input)
#                 - Bug Fixing - Grab automatically xrdp/xorgxrdp package version to avoid
#                   issues when upgrade operation performed (Thanks to Hiero for this input)
#         : 1.2.1 - Adding Support to Ubuntu 20.10 + Removed support for Ubuntu 19.10
#           1.2   - Adding Support to Ubuntu 20.04 + Removed support for Ubuntu 19.04
#                 - Stricter Check for HWE Package (thanks to Andrej Gantvorg)
#                 - Changed code in checking where to copy image for login screen customization
#                 - Fixed Bug checking SSL group membership
#                 - Updating background color xrdp login screen
#                 - Updating pkgversion to x.13 for checkinstall process
#         : 1.1   - Tackling multiple run of the script
#                 - Improved checkinstall method/check ssl group memberhsip
#                 - Replaced ~/Downloads by a variable
#         : 1.0   - Added remove option + Final optimization
#         : 0.9   - updated compile section to use checkinstall
#         : 0.8   - Updated the fix_theme function to add support for Ubuntu 16.04
#         : 0.7   - Updated prereqs function to add support for Ubuntu 16.04
#         : 0.6   - Adding logic to detect Ubuntu version for U16.04
#         : 0.5   - Adding env variable Fix
#         : 0.4   - Adding SSL Fix
#         : 0.3   - Adding custom login screen option
#         : 0.2   - Adding new code for passing parameters
#         : 0.1   - Initial Script (merging custom & Std)
# Disclaimer : Script provided AS IS. Use it at your own risk....
#              You can use this script and distribute it as long as credits are kept
#              in place and unchanged
####################################################################################################

#---------------------------------------------------#
# Variables and Constants                           #
#---------------------------------------------------#

#--Automating Script versioning
ScriptVer="1.3"

#--Detecting  OS Version
version=$(lsb_release -sd)
codename=$(lsb_release -sc)
Release=$(lsb_release -sr)

#--Detecting variable related to Desktop interface and Directory path
DesktopVer="$XDG_CURRENT_DESKTOP"
SessionVer="$GNOME_SHELL_SESSION_MODE"
ConfDir="$XDG_DATA_DIRS"

#Initialzing other variables
modetype="unknown"

#--------------------------------------------------------------------------#
# -----------------------Function Section - DO NOT MODIFY -----------------#
#--------------------------------------------------------------------------#

#---------------------------------------------------#
# Function 0  - check for supported OS version  ....#
#---------------------------------------------------#

check_os()
{
echo
/bin/echo -e "\e[1;33m   |-| Detecting OS version        \e[0m"

case $version in

   *"Ubuntu 20.04"*)
     /bin/echo -e "\e[1;32m       |-| OS Version : $version\e[0m"
     /bin/echo -e "\e[1;32m       |-| Desktop Version : $DesktopVer\e[0m"
    ;;

   *"Ubuntu 22.04"*)
     / bin/echo -e "\e[1;32m       |-| OS Version : $version\e[0m"
     /bin/echo -e "\e[1;32m       |-| Desktop Version : $DesktopVer\e[0m"
    ;;

   *)
     /bin/echo -e "\e[1;31m  !--------------------------------------------------------------!\e[0m"
     /bin/echo -e "\e[1;31m  ! Your system is not running a supported version !             !\e[0m"
     /bin/echo -e "\e[1;31m  ! The script has been tested only on the following versions    !\e[0m"
     /bin/echo -e "\e[1;31m  ! 20.04.x/22.04                                                !\e[0m"
     /bin/echo -e "\e[1;31m  ! The script is exiting...                                     !\e[0m"
     /bin/echo -e "\e[1;31m  !--------------------------------------------------------------!\e[0m"
     echo
    exit
    ;;
esac


echo
}

#---------------------------------------------------#
# Function 1  - check xserver-xorg-core package....
#---------------------------------------------------#

check_hwe()
{
Release=$(lsb_release -sr)
sudo apt-get install -y xserver-xorg-core
echo

/bin/echo -e "\e[1;33m |-| Detecting xserver-xorg-core package installed \e[0m"

xorg_no_hwe_install_status=$(dpkg-query -W -f ='${Status}\n' xserver-xorg-core 2>/dev/null)
xorg_hwe_install_status=$(dpkg-query -W -f ='${Status}\n' xserver-xorg-core-hwe-$Release 2>/dev/null)

if [[ "$xorg_hwe_install_status" =~ \ installed$ ]]
then
# – hwe version is installed on the system
/bin/echo -e "\e[1;32m 	|-| xorg package version: xserver-xorg-core-hwe \e[0m"
HWE="yes"
elif [[ "$xorg_no_hwe_install_status" =~ \ installed$ ]]
then
/bin/echo -e "\e[1;32m 	|-| xorg package version: xserver-xorg-core \e[0m"
HWE="no"
else
/bin/echo -e "\e[1;31m 	|-| Error checking xserver-xorg-core flavour \e[0m"
exit 1
fi
}

#---------------------------------------------------#
# Function 2  - Version specific actions needed....
#---------------------------------------------------#

PrepOS()
{
echo

##--Need to use Variables !!!!!
CustomPix="ciab-login.bmp"
CustomColor="4F194C"

}

############################################################################
# INSTALLATION MODE : STANDARD
############################################################################

#---------------------------------------------------#
# Function 3  - Install xRDP Software....
#---------------------------------------------------#

install_xrdp()
{
echo
/bin/echo -e "\e[1;33m   |-| Installing xRDP packages       \e[0m"
echo
sudo apt-get install xrdp -y
}

############################################################################
# ADVANCED INSTALLATION MODE : CUSTOM INSTALLATION
############################################################################

#---------------------------------------------------#
# Function 4 - Install Prereqs...
#---------------------------------------------------#

install_prereqs() {

echo
/bin/echo -e "\e[1;33m   |-|Installing prerequisites packages       \e[0m"
echo

#--End Debian Specific --#

#Install packages
sudo apt-get -y install git libx11-dev libxfixes-dev libssl-dev libpam0g-dev libtool libjpeg-dev flex bison gettext
sudo apt-get -y install autoconf libxml-parser-perl libfuse-dev xsltproc libxrandr-dev python3-libxml2 nasm fuse pkg-config git intltool checkinstall
echo



echo

#-- check if no error during Installation of missing packages
if [ $? -eq 0 ]
then
/bin/echo -e "\e[1;33m   |-| Preprequesites installation successfully       \e[0m"
else
echo
echo
/bin/echo -e "\e[1;31m   !---------------------------------------------!\e[0m"
/bin/echo -e "\e[1;31m   !   Error while installing prereqs            !\e[0m"
/bin/echo -e "\e[1;31m   !   The Script is exiting....                 !\e[0m"
/bin/echo -e "\e[1;31m   !---------------------------------------------!\e[0m"
exit
fi

#-- check if hwe stack needed or not
#-no-hwe
/bin/echo -e "\e[1;32m       |-| xorg package version: xserver-xorg-core \e[0m"
echo
sudo apt-get install -y xserver-xorg-dev xserver-xorg-core
}

#---------------------------------------------------#
# Function 5 - Download XRDP Binaries...
#---------------------------------------------------#
get_binaries() {
echo
/bin/echo -e "\e[1;33m   |-| Downloading xRDP Binaries...Proceeding     \e[0m"
echo

cd ${INSTALL_DIR}

#Check if xrdp folder already exists.  if yes; delete it and download again in order to get latest version
if [ -d "${INSTALL_DIR}/xrdp" ]
then
	sudo rm -rf ./xrdp
fi

#Check if xorgxrdp folder already exists.  if yes; delete it and download again in order to get latest version
if [ -d "{INSTALL_DIR}/xorgxrdp" ]
then
	sudo rm -rf ./xorgxrdp
fi

## -- Download the latest xrdp and xorgxrdp files
echo
# To solve your issue, you can try to add the option --recursive in the git clone command used to download xrdp and xorgxrdp packages
git clone --recursive https://github.com/neutrinolabs/xrdp.git

echo
/bin/echo -e "\e[1;32m       |-|  Downloading xorgxrdp Binaries...     \e[0m"
echo

git clone --recursive https://github.com/neutrinolabs/xorgxrdp.git

}

#---------------------------------------------------#
# Function 6 - compiling xrdp...
#---------------------------------------------------#
compile_source() {
echo
/bin/echo -e "\e[1;33m   |-| Compiling xRDP Binaries...Proceeding     \e[0m"
echo

cd ${INSTALL_DIR}/xrdp

#Get the release version automatically
pkgver=$(git describe  --abbrev=0 --tags  | cut -dv -f2)

sudo ./bootstrap
sudo ./configure --enable-fuse --enable-jpeg --enable-rfxcodec
sudo make

#-- check if no error during compilation
if [ $? -eq 0 ]
then
echo
/bin/echo -e "\e[1;32m       |-|  Make Operation Completed successfully....xRDP     \e[0m"
echo
else
echo
/bin/echo -e "\e[1;31m   !---------------------------------------------!\e[0m"
/bin/echo -e "\e[1;31m   !   Error while Executing make                !\e[0m"
/bin/echo -e "\e[1;31m   !   The Script is exiting....                 !\e[0m"
/bin/echo -e "\e[1;31m   !---------------------------------------------!\e[0m"
exit
fi
sudo checkinstall --pkgname=xrdp --pkgversion=$pkgver --pkgrelease=1 --default

#xorgxrdp package compilation
echo
/bin/echo -e "\e[1;32m       |-|  Make Operation Completed successfully....xorgxrdp     \e[0m"
echo

cd ${INSTALL_DIR}/xorgxrdp

#Get the release version automatically
pkgver=$(git describe  --abbrev=0 --tags  | cut -dv -f2)

sudo ./bootstrap
sudo ./configure
sudo make

# check if no error during compilation
if [ $? -eq 0 ]
then
echo
/bin/echo -e "\e[1;33m   |-| Compilation Completed successfully...Proceeding    \e[0m"
echo
else
echo
/bin/echo -e "\e[1;31m   !---------------------------------------------!\e[0m"
/bin/echo -e "\e[1;31m   !   Error while Executing make                !\e[0m"
/bin/echo -e "\e[1;31m   !   The Script is exiting....                 !\e[0m"
/bin/echo -e "\e[1;31m   !---------------------------------------------!\e[0m"
exit
fi
sudo checkinstall --pkgname=xorgxrdp --pkgversion=1:$pkgver --pkgrelease=1 --default
}

#---------------------------------------------------#
# Function 7 - create services ....
#---------------------------------------------------#
enable_service() {
echo
/bin/echo -e "\e[1;33m   |-| Creating and configuring xRDP services    \e[0m"
echo
sudo systemctl daemon-reload
sudo systemctl enable xrdp.service
sudo systemctl enable xrdp-sesman.service
sudo systemctl start xrdp

}

############################################################################
# COMMON FUNCTIONS - WHATEVER INSTALLATION MODE - Version Specific !!!
############################################################################

#--------------------------------------------------------------------------#
# Function 8 - Install Tweaks Utilty if Gnome desktop used (Optional) .... #
#--------------------------------------------------------------------------#
install_tweak()
{
echo
/bin/echo -e "\e[1;33m   |-| Checking if Tweaks needs to be installed....    \e[0m"
if [[ "$DesktopVer" != *"GNOME"* ]]
then
/bin/echo -e "\e[1;32m       |-|  Gnome Tweaks not needed...Proceeding...     \e[0m"
echo
else
/bin/echo -e "\e[1;32m       |-|  Installing Gnome Tweaks Utility...Proceeding... \e[0m"
echo
	if [[ *"$version"* = *"Ubuntu 22.04"*  ]]
    then
	#if Ubuntu 21.10 - new version of th tool.....
		sudo apt-get install gnome-tweaks -y
		sudo apt-get install gnome-shell-extensions -y
	else
		sudo apt-get install gnome-tweak-tool -y
	fi
fi
}

#--------------------------------------------------------------------#
# Fucntion 9 - Allow console Access ....(seems optional in u18.04)
#--------------------------------------------------------------------#

allow_console()
{
echo
/bin/echo -e "\e[1;33m   |-| Configuring Allow Console Access...    \e[0m"
echo
# Checking if Xwrapper file exists
if [ -f /etc/X11/Xwrapper.config ]
then
sudo sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config
else
	sudo bash -c "cat >/etc/X11/Xwrapper.config" <<EOF
	allowed_users=anybody
EOF
fi
}

#---------------------------------------------------#
# Function 10 - create policies exceptions ....
#---------------------------------------------------#
create_polkit()
{
echo
/bin/echo -e "\e[1;33m   |-| Creating Polkit exceptions rules...    \e[0m"
echo


#All Ubuntu versions,Debian Version, Pop OS version
sudo bash -c "cat >/etc/polkit-1/localauthority/50-local.d/45-allow.colord.pkla" <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

#Not to apply to Ubuntu 18.04 version but to others....This caused an issue on Ubuntu 18.04
if [[  "$version" !=  *"Ubuntu 18.04"* ]];
then
sudo bash -c "cat >/etc/polkit-1/localauthority/50-local.d/46-allow-update-repo.pkla" <<EOF
[Allow Package Management all Users]
Identity=unix-user:*
Action=org.freedesktop.packagekit.system-sources-refresh;org.freedesktop.packagekit.system-network-proxy-configure
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF
fi

#=====================================================================================================================
#-- "KDE Desktop" Specific  - can be detected only at run time of the script


===================================================================================================================
# If the KDE Desktop was selected for the CIAB LXD Desktop Container a "flag" file named "fix-kde.flag" will have
# neem created.
#
# If "fix-kde.flage file exists there are several config changes that need to be added/modified
#===================================================================================================================

FILE=${INSTALL_DIR}fix-kde.flag
if [ -f $FILE ]; then
sudo bash -c "cat >/etc/polkit-1/localauthority/50-local.d/47-allow-networkd.pkla" <<EOF
[Allow Network Control all Users]
Identity=unix-user:*
Action=org.freedesktop.NetworkManager.network-control
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
fi

}

#---------------------------------------------------#
# Function 11 - Fixing Theme and Extensions ....
#---------------------------------------------------#

fix_theme()
{
echo
/bin/echo -e "\e[1;33m   |-| Fixing Themes and Extensions....    \e[0m"
echo

# Checking if script has run already 
if [ -f /etc/xrdp/startwm.sh.griffon ]
then
sudo rm /etc/xrdp/startwm.sh
sudo mv /etc/xrdp/startwm.sh.griffon /etc/xrdp/startwm.sh
fi 

#Backup the file before modifying it
sudo cp /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.griffon
echo

# Custom code for Budgie Desktop 
if [[ "$DesktopVer" == *"Budgie"* ]]
then 
sudo sed -i "4 a #Improved Look n Feel Method\ncat <<EOF > ~/.xsessionrc\nbudgie-desktop\nexport GNOME_SHELL_SESSION_MODE=$SessionVer\nexport XDG_CURRENT_DESKTOP=$DesktopVer\nexport XDG_DATA_DIRS=$ConfDir\nEOF\n" /etc/xrdp/startwm.sh
else
sudo sed -i "4 a #Improved Look n Feel Method\ncat <<EOF > ~/.xsessionrc\nexport GNOME_SHELL_SESSION_MODE=$SessionVer\nexport XDG_CURRENT_DESKTOP=$DesktopVer\nexport XDG_DATA_DIRS=$ConfDir\nEOF\n" /etc/xrdp/startwm.sh
fi
echo

}

#---------------------------------------------------#
# Function 12 - Enable Sound Redirection ....
#---------------------------------------------------#
enable_sound()
{
echo
/bin/echo -e "\e[1;33m   |-| Enabling Sound Redirection....    \e[0m"
echo

pulsever=$(pulseaudio --version | awk '{print $2}')

/bin/echo -e "\e[1;32m       |-| Install additional packages..     \e[0m"

# Step 1 - Enable Source Code Repository
sudo apt-add-repository -s -y 'deb http://archive.ubuntu.com/ubuntu/ '$codename' main restricted'
sudo apt-add-repository -s -y 'deb http://archive.ubuntu.com/ubuntu/ '$codename' restricted universe main multiverse'
sudo apt-add-repository -s -y 'deb http://archive.ubuntu.com/ubuntu/ '$codename'-updates restricted universe main multiverse'
sudo apt-add-repository -s -y 'deb http://archive.ubuntu.com/ubuntu/ '$codename'-backports main restricted universe multiverse'
sudo apt-add-repository -s -y 'deb http://archive.ubuntu.com/ubuntu/ '$codename'-security main restricted universe main multiverse'
sudo apt-get update

# Step 2 - Install Some PreReqs
sudo apt-get install git libpulse-dev autoconf m4 intltool build-essential dpkg-dev libtool libsndfile-dev libcap-dev -y libjson-c-dev
sudo apt build-dep pulseaudio -y
/bin/echo -e "\e[1;32m       |-| Download pulseaudio sources files..     \e[0m" 

# Step 3 -  Download pulseaudio source in /tmp directory - Debian source repo should be already enabled
cd /tmp
sudo apt source pulseaudio


/bin/echo -e "\e[1;32m       |-| compile pulseaudio sources files..     \e[0m"

# Step 4 - Compile based on OS version

cd /tmp/pulseaudio-$pulsever*
PulsePath=$(pwd)

if [[ *"$version"* = *"Ubuntu 22.04"*  ]]
then
    #Build - new way using meson and replacing configure old school approach
    sudo meson --prefix=$PulsePath build
    sudo ninja -C build install
else
    sudo ./configure
fi

# step 5 - Download xrdp sound modules
/bin/echo -e "\e[1;32m       |-| Compiling and building xRDP Sound modules...     \e[0m" 
sudo git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
cd pulseaudio-module-xrdp

# step 6 - Check if config.h file is missing...if missing..copy file from somewhere 
if [ -f $PulsePath/pulseaudio-module-xrdp/config.h ]
then
	/bin/echo -e "\e[1;32m       |-| Config.h present..Proceeding...     \e[0m" 
else
	/bin/echo -e "\e[1;32m       |-| Config.h seems missing...Dirty fix applied..     \e[0m" 
	sudo cp $PulsePath/build/config.h $PulsePath/pulseaudio-module-xrdp  
fi

# Step 7 - Create xrdp sound modules

	sudo ./bootstrap 
	sudo ./configure PULSE_DIR=$PulsePath
	sudo make
	#this will install modules in /usr/lib/pulse* directory
	sudo make install

# Step 8 copy files to correct location (as defined in /etc/xrdp/pulse/default.pa)

if [[ *"$version"* = *"Ubuntu 22.04"*  ]]
then 
    /bin/echo -e "\e[1;32m       |-| copy generated files in target folder....     \e[0m" 
    cd /usr/lib/pulse*/modules   #new location for the module 
    if [ -d /var/lib/xrdp-pulseaudio-installer ]
	then
		 sudo install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so
	else
    	sudo mkdir /var/lib/xrdp-pulseaudio-installer  # this is not created automatically 
    	sudo install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so
    	echo
	fi
else
    /bin/echo -e "\e[1;32m       |-| copy generated files in target folder....     \e[0m"
    cd /tmp/pulseaudio-$pulsever/pulseaudio-module-xrdp/src/.libs
    sudo install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so
    echo
fi

}

#---------------------------------------------------#
# Function 13 - Custom xRDP Login Screen ....
#---------------------------------------------------#
custom_login()
{

echo
/bin/echo -e "\e[1;33m   |-| Customizing xRDP login screen       \e[0m" 
/bin/echo -e "\e[1;33m   |-| Custom actions based on OS Version....       \e[0m"

cd ${INSTALL_DIR}

#Check if script has run once...
if [ -f /etc/xrdp/xrdp.ini.ciab ]
then
sudo rm /etc/xrdp/xrdp.ini
sudo mv /etc/xrdp/xrdp.ini.ciab /etc/xrdp/xrdp.ini
fi

#Backup file
sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.ciab

#Check where to copy the logo file
echo
sudo cp $CustomPix /usr/local/share/xrdp
sudo sed -i "s/ls_logo_filename=/ls_logo_filename=\/usr\/local\/share\/xrdp\/$CustomPix/g" /etc/xrdp/xrdp.ini


sudo sed -i 's/blue=009cb5/blue=dedede/' /etc/xrdp/xrdp.ini
sudo sed -i 's/#white=ffffff/white=dedede/' /etc/xrdp/xrdp.ini
sudo sed -i 's/#ls_title=My Login Title/ls_title=CIAB LXD Container Desktop/' /etc/xrdp/xrdp.ini
sudo sed -i "s/ls_top_window_bg_color=009cb5/ls_top_window_bg_color=$CustomColor/" /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_bg_color=dedede/ls_bg_color=ffffff/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_x_pos=55/ls_logo_x_pos=2/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_y_pos=50/ls_logo_y_pos=22/' /etc/xrdp/xrdp.ini
}

#---------------------------------------------------#
# Function 14 - Fix SSL Minor Issue ....
#---------------------------------------------------#
fix_ssl()
{
echo
/bin/echo -e "\e[1;33m   |-| Fixing SSL Permissions settings...       \e[0m"
echo
if id -Gn xrdp | grep ssl-cert
then
	/bin/echo -e "\e[1;32m   !--xrdp already member ssl-cert...Skipping ---!\e[0m"
else
	sudo adduser xrdp ssl-cert
fi
}

#---------------------------------------------------#
# Function 15 - Fixing env variables in XRDP ....
#---------------------------------------------------#
fix_env()
{
echo
/bin/echo -e "\e[1;33m   |-| Fixing xRDP env Variables...       \e[0m"
echo
echo
echo
#=======================================================================================================
# in /etc/sesman.ini change the default fusemount name
# from
#     "FuseMountName=thinclient_drives"
# to
#     "FuseMountName=ciab-share"
#
# This will force xrdp to create the FUSE Desktop folder used for uploads/downloads from
# the client to the remote desktop to become named 'ciab-share' instead of "thinclient_drives"

sudo sed -i 's/FuseMountName=thinclient_drives/FuseMountName=ciab-share/' /etc/xrdp/sesman.ini


# Add the following line to /etc/pam.d/xrdp-sesman if not present
if grep -Fxq "session required pam_env.so readenv=1 user_readenv=0" /etc/pam.d/xrdp-sesman
   then
            echo "Env settings already set"
   else
		sudo sed -i '1 a session required pam_env.so readenv=1 user_readenv=0' /etc/pam.d/xrdp-sesman
 fi
}

#---------------------------------------------------#
# Function 17 - Removing XRDP Packages ....
#---------------------------------------------------#
remove_xrdp()
{
echo
/bin/echo -e "\e[1;33m   !---------------------------------------------!\e[0m"
/bin/echo -e "\e[1;33m   ! Removing xRDP Packages...                   !\e[0m"
/bin/echo -e "\e[1;33m   !---------------------------------------------!\e[0m"
echo

#remove the xrdplog file created by the script
sudo rm /etc/xrdp/xrdp-installer-check.log

#----remove xrdp package
sudo systemctl stop xrdp
sudo systemctl disable xrdp
sudo apt-get autoremove xrdp -y
sudo apt-get purge xrdp -y

#---remove xorgxrdp
sudo systemctl stop xorgxrdp
sudo systemctl disable xorgxrdp


sudo apt-get autoremove xorgxrdp -y
sudo apt-get purge xorgxrdp -y

#---Cleanup files

#Remove xrdp folder
if [ -d "${INSTALL_DIR}/xrdp" ]
then
	sudo rm -rf xrdp
fi

#Remove xorgxrdp folder
if [ -d "${INSTALL_DIR}/xorgxrdp" ]
then
	sudo rm -rf xorgxrdp
fi

#Remove custom xrdp logo file
if [ -f "${INSTALL_DIR}/$CustomPix" ]
then
	sudo rm -f  "${INSTALL_DIR}/$CustomPix"
fi

sudo systemctl daemon-reload

}

sh_credits()
{
echo
/bin/echo -e "\e[1;36m   !----------------------------------------------------------------!\e[0m"
/bin/echo -e "\e[1;36m   ! Installation Completed...Please test your xRDP configuration   !\e[0m" 
/bin/echo -e "\e[1;36m   ! If Sound option selected, shutdown your machine completely     !\e[0m"
/bin/echo -e "\e[1;36m   ! start it again to have sound working as expected               !\e[0m"
/bin/echo -e "\e[1;36m   !                                                                !\e[0m"
/bin/echo -e "\e[1;36m   ! Credits : Written by Griffon - October 2021                    !\e[0m"
/bin/echo -e "\e[1;36m   !           www.c-nergy.be -xrdp-installer-v$ScriptVer.sh               !\e[0m"
/bin/echo -e "\e[1;36m   !           ver $ScriptVer                                              !\e[0m"
/bin/echo -e "\e[1;36m   !----------------------------------------------------------------!\e[0m"
echo
}


#---------------------------------------------------#
# SECTION FOR OPTIMIZING CODE USAGE...              #
#---------------------------------------------------#

install_common()
{
#install_tweak	
allow_console
create_polkit
fix_theme
fix_ssl
fix_env
}

install_custom()
{
install_prereqs
get_binaries
compile_source
enable_service

}

#--------------------------------------------------------------------------#
# -----------------------END Function Section             -----------------#
#--------------------------------------------------------------------------#

#--------------------------------------------------------------------------#
#------------                 MAIN SCRIPT SECTION       -------------------# 
#--------------------------------------------------------------------------#

#---------------------------------------------------#
# Script Version information Displayed              #
#---------------------------------------------------#

echo
/bin/echo -e "\e[1;36m   !-----------------------------------------------------------------!\e[0m"
/bin/echo -e "\e[1;36m   !   CIAB XRDP Installer is a modified version of                  !\e[0m"
/bin/echo -e "\e[1;36m   !                                                                 !\e[0m"
/bin/echo -e "\e[1;36m   !        xrdp-installer-$ScriptVer Script                                !\e[0m"
/bin/echo -e "\e[1;36m   !                                                                 !\e[0m"
/bin/echo -e "\e[1;36m   !   Written by Griffon - October 2021 - www.c-nergy.be            !\e[0m"
/bin/echo -e "\e[1;36m   !                                                                 !\e[0m"
/bin/echo -e "\e[1;36m   !-----------------------------------------------------------------!\e[0m"
echo

#----------------------------------------------------------#
# Step 0 -Detecting if Parameters passed to script ....    #
#----------------------------------------------------------#
for arg in "$@"
do
    #Help Menu Requested
    if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
    then
                echo "Usage Syntax and Examples"
                echo
                echo " --custom or -c           custom xRDP install (compilation from sources)"
				echo " --loginscreen or -l      customize xRDP login screen"
                echo " --remove or -r           removing xRDP packages"
                echo " --sound or -s            enable sound redirection in xRDP"
                echo
                echo "example                                                      "
                echo
                echo " ./xrdp-installer-$ScriptVer.sh -c -s  custom install with sound redirection"
                echo " ./xrdp-installer-$ScriptVer.sh -l     standard install with custom login screen"
                echo " ./xrdp-installer-$ScriptVer.sh        standard install no additional features"
                echo
                exit
    fi

    #======================================================================================================
    # For CIAB we always enable sound redirection, the ciab login banner, and build from the
    # latest source code

    fixSound="yes"

    fixlogin="yes"

    adv="yes"

    if [ "$arg" == "--remove" ] || [ "$arg" == "-r" ]
    then
        removal="yes"
    fi
done

#--------------------------------------------------------------------------------#
#-- Step 0 - Check that the script is run as normal user and not as root....
#-------------------------------------------------------------------------------#

if [[ $EUID -ne 0 ]]; then
	/bin/echo -e "\e[1;36m   !-------------------------------------------------------------!\e[0m"
	/bin/echo -e "\e[1;36m   !  Standard user detected....Proceeding....                   !\e[0m"
	/bin/echo -e "\e[1;36m   !-------------------------------------------------------------!\e[0m"
else
	echo
	/bin/echo -e "\e[1;31m   !-------------------------------------------------------------!\e[0m"
	/bin/echo -e "\e[1;31m   !  Script launched with sudo command. Script will not run...  !\e[0m"
	/bin/echo -e "\e[1;31m   !  Run script a standard user account (no sudo). When needed  !\e[0m"
	/bin/echo -e "\e[1;31m   !  script will be prompted for password during execution      !\e[0m"
	/bin/echo -e "\e[1;31m   !                                                             !\e[0m"
	/bin/echo -e "\e[1;31m   !  Exiting Script - No Install Performed !!!                  !\e[0m"
	/bin/echo -e "\e[1;31m   !-------------------------------------------------------------!\e[0m"
	echo
	#sh_credits
	exit
fi

#---------------------------------------------------#
#-- Step 1 - Try to Detect Ubuntu Version....       #
#---------------------------------------------------#

check_os

#--------------------------------------------------------#
#-- Step 2 - Try to detect if HWE Stack needed or not....#
#--------------------------------------------------------#

check_hwe

#--------------------------------------------------------------------------------#
#-- Step 3 - Check if Removal Option Selected
#--------------------------------------------------------------------------------#

if [ "$removal" = "yes" ];
then
	remove_xrdp
	echo
	sh_credits
	exit
fi

#---------------------------------------------------------#
# Step 4 - Executing the installation & config tasks .... #
#---------------------------------------------------------#

#-- Detect if multiple runs and install mode used.....
echo
/bin/echo -e "\e[1;33m   |-| Checking if script has run at least once...        \e[0m"
if [ -f /etc/xrdp/xrdp-installer-check.log ]
then
	modetype=$(sed -n 1p /etc/xrdp/xrdp-installer-check.log)
	/bin/echo -e "\e[1;32m       |-| Script has already run. Detected mode...: $modetype\e[0m"

else
	/bin/echo -e "\e[1;32m       |-| First run or xrdp-installer-check.log deleted. Detected mode : $modetype        \e[0m"
fi

#---------------------------------------------------------------------------------------
#- Detect Standard vs custom install mode and additional options...
#----------------------------------------------------------------------------------------

	if [ "${adv}" = "yes" ];
	then
		echo
		/bin/echo -e "\e[1;33m   |-| custom installation mode detected.        \e[0m"

		if [ $modetype = "custom" ];
		then
			/bin/echo -e "\e[1;36m           |-| xrdp already installed - custom mode....skipping xrdp install        \e[0m"
			PrepOS
		else
			/bin/echo -e "\e[1;36m           |-| Proceed custom xrdp installation packages and customization tasks      \e[0m"
			PrepOS
			install_custom
			install_common

			#create the file used a detection method
			sudo touch /etc/xrdp/xrdp-installer-check.log
			sudo bash -c 'echo "custom" >/etc/xrdp/xrdp-installer-check.log'
		fi

	else
		echo
			/bin/echo -e "\e[1;33m   |-| Additional checks Std vs Custom Mode..       \e[0m"
		if [ $modetype = "standard" ];
		then 
			/bin/echo -e "\e[1;35m           |-| xrdp already installed - standard mode....skipping install  \e[0m"
			PrepOS
		elif [ $modetype = "custom" ]
        then 
        	/bin/echo -e "\e[1;35m           |-| Checking for additional parameters"
		else
			/bin/echo -e "\e[1;32m       |-| Proceed standard xrdp installation packages and customization tasks      \e[0m"
			PrepOS
			install_xrdp
			install_common

			#create the file
			sudo touch /etc/xrdp/xrdp-installer-check.log
			sudo bash -c 'echo "standard" >/etc/xrdp/xrdp-installer-check.log'
		fi
	fi  #end if Adv option

#---------------------------------------------------------------------------------------
#- Check for Additional Options selected
#----------------------------------------------------------------------------------------

enable_sound

echo
custom_login

#---------------------------------------------------------------------------------------
#- show Credits and finishing script
#---------------------------------------------------------------------------------------

sh_credits


#===================================================================================================================
# If the Budgie Desktop was selected for the CIAB LXD Desktop Container "flag" file named "fix-budgie.flag".
# There is a command that needs to be inserted into "/etc/xrdp/startwm.sh".
#===================================================================================================================

FILE=${INSTALL_DIR}\/fix-budgie.flag
if [ -f $FILE ]; then

        # Replace the 2nd occurence of "wm_start" in/etc/xrdp/startwm.sh
        # with "budgie-desktop"

        sudo sed -i 's+wm_start+budgie-desktop+g' /etc/xrdp/startwm.sh

        sudo sed -i 's+budgie-desktop()+wm_start()+g' /etc/xrdp/startwm.sh

        # clean up by deleting our our fx-budgie "flag" file
        sudo rm $FILE
fi

#===================================================================================================================
# If the KDE Desktop was selected for the CIAB LXD Desktop Container a "flag" file named "fix-kde.flag" will have
# neem created.
#
# If "fix-kde.flage file exists there are several config changes that need to be added/modified
#===================================================================================================================

FILE=${INSTALL_DIR}/fix-kde.flag
if [ -f ${FILE} ]; then

cat <<EOF | sudo tee /etc/X11/default-display-manager
/usr/bin/sddm
EOF

        echo "startplasma-x11" > /home/${USER_NAME}/.xsession
        D=/usr/share/plasma:/usr/local/share:/usr/share:/var/lib/snapd/desktop
        C=/etc/xdg/xdg-plasma:/etc/xdg
        C=${C}:/usr/share/kubuntu-default-settings/kf5-settings
cat <<EOF > ~/.xsessionrc
export XDG_SESSION_DESKTOP=KDE
export XDG_DATA_DIRS=${D}
export XDG_CONFIG_DIRS=${C}
EOF

cat <<EOF | \
  sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-NetworkManager.pkla
[xrdp-Netowrkmanager]
Identity=unix-group:sudo
Action=org.freedesktop.NetworkManager.network-control
ResultAny=no
ResultInactive=yes
ResultActive=yes
EOF

cat <<EOF | \
  sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-packagekit.pkla
[xrdp-packagekit]
Identity=unix-group:sudo
Action=org.freedesktop.packagekit.system-sources-refresh
ResultAny=no
ResultInactive=yes
ResultActive=yes
EOF

   sudo systemctl restart polkit

   # remove the flag file
   rm ${FILE}

fi # KDE install complete
