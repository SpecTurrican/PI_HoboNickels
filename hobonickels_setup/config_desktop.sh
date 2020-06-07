#!/bin/bash

# BASICS
SCRIPT_VERSION="06062020"
COIN_NAME="HoboNickels"
COIN=$(echo ${COIN_NAME} | tr '[:upper:]' '[:lower:]')

# DIRS
HOME="/home/${COIN}/"
COIN_HOME="${HOME}.${COIN_NAME}/"
INSTALL_DIR="/root/PI_${COIN_NAME}/"
COIN_MEDIA="${HOME}MEDIA/"
COIN_WALLPAPER="${COIN}_wallpaper.jpg"
COIN_ICON="${COIN}_icon.png"

# Install Script
SCRIPT_DIR="${INSTALL_DIR}${COIN}_setup/"
SCRIPT_NAME="config_desktop.sh"

# Logfile
LOG_DIR="${INSTALL_DIR}logfiles/"
LOG_FILE="config_desktop.log"

# Commands
HOME_USER_COMMAND="sudo -u ${COIN}"

# Application
APPS="gedit ristretto"


app_install () {

	sleep 5
	apt-get -y update
	sleep 5
	apt-get -y upgrade
	sleep 5
	apt-get install -y $APPS
	sleep 2

}

config_desktop () {

	#
	# Copy Wallpaper and Icons for Desktop
	[ ! -d "$COIN_MEDIA" ] && $HOME_USER_COMMAND /bin/mkdir -p $COIN_MEDIA
	cp ${SCRIPT_DIR}${COIN_WALLPAPER} ${COIN_MEDIA}
	cp ${SCRIPT_DIR}${COIN_ICON} ${COIN_MEDIA}
	/bin/chown -R -f ${COIN} ${COIN_MEDIA}

	#
	# Set Desktop Application
	[ ! -d "${HOME}.local/share/applications" ] && $HOME_USER_COMMAND /bin/mkdir -p ${HOME}.local/share/applications
	[ ! -d "${HOME}Desktop" ] && $HOME_USER_COMMAND /bin/mkdir -p ${HOME}Desktop

	#
	# Set Menu Application
	$HOME_USER_COMMAND echo "
		[Desktop Entry]
		Name=${COIN_NAME} QT
		Comment=Blockchain Wallet from ${COIN_NAME}
		Exec=${COIN_NAME}-qt
		Icon=${COIN_MEDIA}${COIN_ICON}
		Terminal=false
		Type=Application
		Categories=Blockchain;
		Keywords=blockchain;wallet;${COIN};${COIN_NAME};
	" > ${HOME}.local/share/applications/${COIN}-qt.desktop

	#
	# Set Desktop link
	$HOME_USER_COMMAND echo "
		[Desktop Entry]
		Type=Link
		Name=${COIN_Name} QT
		Icon=${COIN_MEDIA}${COIN_ICON}
		URL=${HOME}.local/share/applications/${COIN}-qt.desktop" > ${HOME}Desktop/${COIN}-qt.desktop

	#
	# Set Desktop Wallpaper
	[ ! -d "${HOME}.config/pcmanfm/LXDE-pi" ] && $HOME_USER_COMMAND /bin/mkdir -p ${HOME}.config/pcmanfm/LXDE-pi
	$HOME_USER_COMMAND echo "
		[*]
		desktop_bg=#ffffffffffff
		desktop_shadow=#ffffffffffff
		desktop_fg=#000000000000
		desktop_font=Monospace 12
		wallpaper=${COIN_MEDIA}${COIN_WALLPAPER}
		wallpaper_mode=center
		show_documents=0
		show_trash=1
		show_mounts=1
	" > ${HOME}.config/pcmanfm/LXDE-pi/desktop-items-0.conf

	#
	# Set Desktop
	[ ! -d "${HOME}.config/lxsession/LXDE-pi" ] && $HOME_USER_COMMAND /bin/mkdir -p ${HOME}.config/lxsession/LXDE-pi
	$HOME_USER_COMMAND echo "
		[GTK]
		sGtk/ColorScheme=selected_bg_color:##878791919b9b\nselected_fg_color:#f0f0f0f0f0f0\nbar_bg_color:#f5f5e6e64b4b\nbar_fg_color:#000000000000\n
		sGtk/FontName=Monospace 12
		iGtk/ToolbarIconSize=3
		sGtk/IconSizes=gtk-large-toolbar=24,24
		iGtk/CursorThemeSize=24" > ${HOME}.config/lxsession/LXDE-pi/desktop.conf

	#
	# Copy info.txt on Desktop
	$HOME_USER_COMMAND cp ${HOME}info.txt ${HOME}Desktop

}

finish () {

	/usr/bin/touch /boot/${COIN}_config_desktop
	echo $SCRIPT_VERSION > /boot/${COIN}_config_desktop
	/usr/bin/crontab -u root -r
	echo "The last step is completed ... reboot in 30 sec ..."
	echo "Have fun!"


}


	#
	# Is the service installed ?

	if [ -f /boot/${COIN}_config_desktop ]; then

		echo "Previous ${COIN}_config_desktop detected. Install aborted."

	else
		app_install
		config_desktop
		finish

	fi

sleep 30
/sbin/reboot