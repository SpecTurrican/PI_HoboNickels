#!/bin/bash

if [[ $EUID -ne 0 ]]; then

	echo "This script must be run as root"

else

	COIN="HoboNickels"
	SETUP=$(echo ${COIN} | tr '[:upper:]' '[:lower:]')
	OS=$(cat /etc/os-release | grep ID=raspbian)
	OS_Version=$(cat /etc/debian_version | grep 10)
	RPI_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
	GIT_URL="https://github.com/SpecTurrican/PI_${COIN}"
	INSTALL_DIR="/root/PI_${COIN}/"
	INSTALL_FILE="${INSTALL_DIR}${SETUP}_setup/install_${SETUP}.sh"
	LOG_DIR="${INSTALL_DIR}logfiles/"
	LOG_FILE="start.log"

	if [ "$RPI_RAM" -lt "3072" ]; then

		echo "Need Raspberry Pi 4 with 4GB Ram or more ... sorry !!!"

	else

	sleep 2
	apt-get -y update && apt-get -y install git

		if [ -n "$OS" ]; then
			if [ -n "OS_Version" ]; then

			cd /root/
			git clone ${GIT_URL}
			chmod 750 -R ${INSTALL_DIR}
			[ ! -d "${LOG_DIR}" ] && /bin/mkdir ${LOG_DIR}
			nohup ${INSTALL_FILE} >${LOG_DIR}${LOG_FILE} 2>&1 &
			clear

			tail -f ${LOG_DIR}${LOG_FILE}

			else

				echo "This script running only below raspian buster... sorry !!!"
				echo " "
				echo "Visit https://www.raspberrypi.org/downloads/raspbian/ "

			fi

		else

			echo "This script running only below raspian buster... sorry !!!"
			echo " "
			echo "Visit https://www.raspberrypi.org/downloads/raspbian/ "

		fi

	fi

fi