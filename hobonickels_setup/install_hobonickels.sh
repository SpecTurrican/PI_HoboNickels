#!/bin/bash

# BASICS
SCRIPT_VERSION="06062020"
COIN_NAME="HoboNickels"
COIN=$(echo ${COIN_NAME} | tr '[:upper:]' '[:lower:]')
COIN_PORT="7372"
COIN_RPCPORT="7373"
COIN_DOWNLOAD="https://github.com/Tranz5/${COIN_NAME}"
COIN_BLOCKCHAIN_VERSION="hbn-snapshot"
COIN_BLOCKCHAIN="https://files.hobomap.info/${COIN_BLOCKCHAIN_VERSION}.zip"
COIND="/usr/local/bin/${COIN}d"
COIN_CLI="/usr/local/bin/${COIN}d"
COIN_BLOCKEXPLORER="https://chainz.cryptoid.info/hbn/api.dws?q=getblockcount"
COIN_NODE="https://chainz.cryptoid.info/hbn/api.dws?q=nodes"

# DIRS
ROOT="/root/"
HOME="/home/${COIN}/"
COIN_ROOT="${ROOT}.${COIN_NAME}"
COIN_HOME="${HOME}.${COIN_NAME}"
INSTALL_DIR="${ROOT}PI_${COIN_NAME}/"
COIN_INSTALL="${ROOT}${COIN_NAME}"
BDB_PREFIX="/usr/local"
COIN_CONFIG="${COIN_ROOT}/${COIN_NAME}.conf"

# DB
DB_VERSION="4.8.30"
DB_FILE="db-${DB_VERSION}.NC.tar.gz"
DB_DOWNLOAD="http://download.oracle.com/berkeley-db/${DB_FILE}"

# LIBRARIES and DEV_TOOLS
SSL_VERSION="1.0"
LIBBOOST_VERSION="1.62"
LIBRARIES="libssl${SSL_VERSION}-dev libboost${LIBBOOST_VERSION}-all-dev libevent-dev libzmq3-dev libqt5gui5 libqt5core5a libqt5dbus5 libqrencode-dev libprotobuf-dev"
DEV_TOOLS="build-essential libtool autotools-dev autoconf cmake pkg-config bsdmainutils git jq unzip fail2ban ufw python3 pkg-config autotools-dev qt5-default qt5-qmake qtbase5-dev-tools qttools5-dev qttools5-dev-tools protobuf-compiler"

# Wallet RPC user and password
rrpcuser="${COIN}pi$(shuf -i 100000000-199999999 -n 1)"
rrpcpassword="$(shuf -i 1000000000-3999999999 -n 1)$(shuf -i 1000000000-3999999999 -n 1)$(shuf -i 1000000000-3999999999 -n 1)"

# Install Script
SCRIPT_DIR="${INSTALL_DIR}${COIN}_setup/"
SCRIPT_NAME="install_${COIN}.sh"
SCRIPT_NAME_NEXT="config_desktop.sh"

# Logfile
LOG_DIR="${INSTALL_DIR}logfiles/"
LOG_FILE="make.log"
LOG_FILE_NEXT="config_desktop.log"

# System Settings
checkForRaspbian=$(cat /proc/cpuinfo | grep 'Revision')
CPU_CORE=$(cat /proc/cpuinfo | grep processor | wc -l)
RPI_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')

# Commands
COIN_D_COMMAND="${COIND} -daemon -conf=${COIN_CONFIG} -datadir=${COIN_ROOT} -walletdir=${COIN_ROOT}"
COIN_CLI_COMMAND="${COIN_CLI} -conf=${COIN_CONFIG} -datadir=${COIN_ROOT}"


start () {

	#
	# Welcome

	echo "*** Welcome to the ${COIN_NAME} World ***"
	echo ""
	echo ""
	echo "Please wait... now configuration the system!"

	# Put here for startup config
	/usr/bin/touch /boot/ssh
	sleep 5


}


app_install () {

	#
	# Install Tools

	sleep 2
	apt-get update && apt-get upgrade -y
	sleep 2
	apt-get install -y ${LIBRARIES} ${DEV_TOOLS}


}


manage_swap () {

	# On a Raspberry Pi, the default swap is 100MB. This is a little restrictive, so we are
	# expanding it to a full 2GB of swap. or disable when RPI4 4GB Version

	if [ "$RPI_RAM" -lt "3072" ]; then
	sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
	fi
	if [ "$RPI_RAM" -gt "3072" ]; then
	swap_off
	fi


}


reduce_gpu_mem () {

	#
	# On the Pi, the default amount of gpu memory is set to be used with the GUI build. Instead
	# we are going to set the amount of gpu memmory to a minimum due to the use of the Command
	# Line Interface (CLI) that we are using in this build. This means we don't have a GUI here,
	# we only use the CLI. So no need to allocate GPU ram to something that isn't being used. Let's
	# assign the param below to the minimum value in the /boot/config.txt file.

	if [ ! -z "$checkForRaspbian" ]; then
		# First, lets not assume that an entry doesn't already exist, so let's purge and preexisting
		# gpu_mem variables from the respective file.
		sed -i '/gpu_mem/d' /boot/config.txt
		#
		# Now, let's append the variable and value to the end of the file.
		echo "gpu_mem=16" >> /boot/config.txt
		echo "GPU memory was reduced to 16MB on reboot."
	fi


}


disable_bluetooth () {

	if [ ! -z "$checkForRaspbian" ]; then

		# First, lets not assume that an entry doesn't already exist, so let's purge any preexisting
		# bluetooth variables from the respective file.
		sed -i '/disable-bt/d' /boot/config.txt
		#
		# Now, let's append the variable and value to the end of the file.
		echo "dtoverlay=disable-bt" >> /boot/config.txt
		#
		# Next, we remove the bluetooth package that was previously installed.
		apt-get remove pi-bluetooth -y
		echo "Bluetooth was uninstalled."

	fi


}


set_network () {

	hhostname="${COIN}$(shuf -i 100000000-999999999 -n 1)"
	echo $hhostname > /etc/hostname && hostname -F /etc/hostname
	sed -i ''s/raspberrypi/${hhostname}/'' /etc/hosts
	echo "Your Hostname is now : ${hhostname}"


}


set_accounts () {

	#
	# We don't always know the condition of the host OS, so let's look for several possibilities.
	# This will disable the ability to log in directly as root.
	sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
	sed -i 's/PermitRootLogin without-password/PermitRootLogin no/' /etc/ssh/sshd_config
	#
	# Set /etc/adduser.conf https://www.techrepublic.com/article/how-to-ensure-all-new-user-home-directories-are-created-without-world-readable-permissions-in-linux/
	sed -i 's/DIR_MODE=0755/DIR_MODE=0770/' /etc/adduser.conf
	#
	# Set the new username and password
	adduser $COIN --disabled-password --gecos ""
	echo "$COIN:$COIN" | chpasswd
	adduser $COIN sudo
	#
	# We only need to lock the Pi account if this is a Raspberry Pi. Otherwise, ignore this step.
	if [ ! -z "$checkForRaspbian" ]; then
		#
		# Let's lock the pi user account, no need to delete it.
		usermod -L -e 1 pi
		echo "The 'pi' login was locked. Please log in with '$COIN'. The password is '$COIN'."
		sleep 5
	fi
	#
	# Set Groups for the new user (same PI user) https://raspberrypi.stackexchange.com/questions/36322/cant-shutdown-or-reboot-from-gui-after-making-new-user
	for GROUP in adm dialout cdrom sudo audio video plugdev games users netdev input spi i2c gpio; do sudo adduser ${COIN} $GROUP; done


}


prepair_system () {

	#
	# prepair the installation

	apt-get autoremove -y
	cd ${ROOT}
	git clone $COIN_DOWNLOAD $COIN_INSTALL
	wget -nv $DB_DOWNLOAD
	tar -xzvf $DB_FILE && rm $DB_FILE
	[ ! -d "$COIN_ROOT" ] && mkdir $COIN_ROOT
	wget -nv $COIN_BLOCKCHAIN
	unzip ${COIN_BLOCKCHAIN_VERSION}.zip
	mv HoboNickels-Snapshot/ $COIN_ROOT && rm ${COIN_BLOCKCHAIN_VERSION}.zip
	chown -R root:root ${COIN_ROOT}


}


prepair_crontab () {

	#
	# prepair crontab for restart

	/usr/bin/crontab -u root -r
	/usr/bin/crontab -u root -l | { cat; echo "@reboot		${SCRIPT_DIR}${SCRIPT_NAME} >${LOG_DIR}${LOG_FILE} 2>&1"; } | crontab -


}


restart_pi () {

	#
	# restart the system

	/usr/bin/touch /boot/${COIN}setup
	echo "SCRIPTVERSION=${SCRIPT_VERSION}" >> /boot/${COIN}setup

	echo "restarting the system... "
	echo " "
	echo "!!!!!!!!!!!!!!!!!"
	echo "!!! New login !!!"
	echo "!!!!!!!!!!!!!!!!!"
	echo "User: ${COIN}  Password: ${COIN}"
	echo " "
	echo " "

	sleep 30

	/sbin/reboot

}


make_db () {

	#
	# make Berkeley DB

	cd ${ROOT}/db-${DB_VERSION}.NC/build_unix/
	../dist/configure --prefix=$BDB_PREFIX --enable-cxx
	if [ "$CPU_CORE" = "4" ]; then
		make -j3
		sleep 30
		make install
		sleep 1
	else
		make
		sleep 5
		make install
		sleep 1
	fi

	echo 'LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:/usr/local/lib"' >> /etc/environment
	echo "/usr/local/lib" >> /etc/ld.so.conf.d/bitcoind.conf
	/sbin/ldconfig
	sleep 1

}


make_coin () {

	#
	# make the wallet qt (with gui)

	#
	# Fix for ARM processors, remove the "-msse2" flags and set to "-march=native"

	sed -i 's/-msse2/-march=native/g' ${COIN_INSTALL}/${COIN_NAME}-qt.pro
	sleep 1

	cd $COIN_INSTALL
	qmake "USE_UPNP=-" "USE_QRCODE=1" "USE_DBUS=1"
	sleep 3
	make all
	sleep 30
	cp ${COIN_NAME}-qt /usr/local/bin
	/usr/bin/strip /usr/local/bin/${COIN_NAME}-qt
	/bin/chmod +x /usr/local/bin/${COIN_NAME}-qt

	#
	# make the wallet console (no gui)

	cd $COIN_INSTALL/src
	#
	# Set for RPI4 4GB Version 
	if [ "$RPI_RAM" -gt "3072" ]; then
		make -f makefile.unix USE_UPNP= -j3
		sleep 30
		cp ${COIN}d /usr/local/bin
	else
	#
	# Set for RPI4 2GB Version
		make -f makefile.unix USE_UPNP= -j2
		sleep 30
		cp ${COIN}d /usr/local/bin
	fi

	/usr/bin/strip ${COIND}
	/bin/chmod +x ${COIND}


}


configure_coin_conf () {

	#
	# Set the coin config file .conf

	COIN_EXTERNALIP=$(curl -s icanhazip.com)

	echo "
	rpcuser=${rrpcuser}
	rpcpassword=${rrpcpassword}
	rpcallowip=127.0.0.1
	port=${COIN_PORT}
	rpcport=${COIN_RPCPORT}
	server=1
	listen=1
	daemon=1
	maxconnections=24
	logtimestamps=1
	txindex=0
	externalip=${COIN_EXTERNALIP}:${COIN_PORT}

	#############
	# NODE LIST #
	#############" > ${COIN_CONFIG}

	COIN_NODES=$(curl -s $COIN_NODE | jq '.[] | .nodes[]' |  /bin/sed 's/"//g')

		for addnode in $COIN_NODES; do
		echo "	addnode=$addnode" >> ${COIN_CONFIG}
		done


}


config_ufw () {

	#
	# Setup for Firewall UFW
	# The default port is COIN_PORT

	/usr/sbin/ufw logging on
	/usr/sbin/ufw allow 22/tcp
	/usr/sbin/ufw limit 22/tcp
	#
	# COIN_PORT
	/usr/sbin/ufw allow ${COIN_PORT}/tcp
	#
	# RDP Port
	/usr/sbin/ufw allow 3389
	#
	/usr/sbin/ufw default deny incoming
	/usr/sbin/ufw default allow outgoing
	yes | /usr/sbin/ufw enable


}


config_fail2ban () {

	#
	# The default ban time for users on port 22 (SSH) is 10 minutes. Lets make this a full 24
	# hours that we will ban the IP address of the attacker. This is the tuning of the fail2ban
	# jail that was documented earlier in this file. The number 86400 is the number of seconds in
	# a 24 hour term.


	echo "
	[sshd]
	enabled	= true
	bantime = 86400
	banaction = ufw
	" > /etc/fail2ban/jail.d/defaults-debian.conf

	# Configure the fail2ban jail and set the frequency to 20 min and 3 polls.

	echo "
	#
	# SSH
	#
	[sshd]
	port		= ssh
	logpath		= %(sshd_log)s
	maxretry = 3
	" > /etc/fail2ban/jail.local

	fail2ban-client reload


}


swap_off () {

	#
	# swap off/disable for safe your SD-Card

	IS_SWAPON=$(/sbin/swapon)
	if [ "$IS_SWAPON" ]; then
	/sbin/swapoff -a
	/usr/sbin/service dphys-swapfile stop
	/bin/systemctl disable dphys-swapfile
	fi


}


configure_service () {

	#
	# Set systemctl

	echo "

	[Unit]
	Description=${COIN_NAME} Service
	After=network.target
	[Service]
	User=root
	Group=root
	Type=forking
	ExecStart=${COIN_D_COMMAND}
	ExecStop=${COIN_CLI_COMMAND} stop
	Restart=always
	PrivateTmp=true
	TimeoutStopSec=90s
	TimeoutStartSec=90s
	StartLimitInterval=180s
	StartLimitBurst=15
	[Install]
	WantedBy=multi-user.target

	" > /etc/systemd/system/${COIN}.service

	/bin/systemctl daemon-reload
	sleep 5
	/bin/systemctl start ${COIN}.service
	/bin/systemctl enable ${COIN}.service >/dev/null 2>&1


}


checkrunning () {

	#
	# Is the service running ?

	echo " ... waiting of ${COIN}.service ... please wait!..."
	sleep 5
	while ! ${COIN_CLI_COMMAND} getinfo >/dev/null 2>&1; do
		sleep 10
		error=$(${COIN_CLI_COMMAND} getinfo 2>&1 | cut -d: -f4 | tr -d "}")
		echo " ... ${COIN}.service is on : loading pls wait! ... $error"
		sleep 5
	done

	echo "${COIN}.service is running !"


}


watch_synch () {

	#
	# Watch synching the blockchain

	sleep 5

	set_blockhigh=$(curl -s ${COIN_BLOCKEXPLORER})
	echo "  The current blockhigh is now : ${set_blockhigh} ..."
	echo "  -----------------------------------------"

	while true; do

	set_blockhigh=$(curl -s ${COIN_BLOCKEXPLORER})
	get_blockhigh=$(${COIN_CLI_COMMAND} getblockcount)

	if [ "$get_blockhigh" -lt "$set_blockhigh" ]
	then
		echo "  ... This may take a long time please wait!..."
		echo "    Block is now: $get_blockhigh / $set_blockhigh"
		sleep 30
	else
		echo "      Complete!..."
		echo "    Block is now: $get_blockhigh / $set_blockhigh"
		echo " "
		sleep 60
		break
	fi
	done


}


finish () {

	#
	# We now write this empty file to the /boot dir. This file will persist after reboot so if
	# this script were to run again, it would abort because it would know it already ran sometime
	# in the past. This is another way to prevent a loop if something bad happens during the install
	# process. At least it will fail and the machine won't be looping a reboot/install over and
	# over. This helps if we have ot debug a problem in the future.

	/usr/bin/touch /boot/${COIN}service
	echo $SCRIPTVERSION > /boot/${COIN}service

	/usr/bin/crontab -u root -r

	#
	# Disable the service for running the QT Version :-)
	systemctl stop ${COIN}.service
	systemctl disable ${COIN}.service
	sleep 10

	#
	# Prepare the service for console
	sed -i ''s/User=root/User=${COIN}/'' /etc/systemd/system/${COIN}.service
	sed -i ''s/Group=root/Group=${COIN}/'' /etc/systemd/system/${COIN}.service
	sed -i ''s#$COIN_ROOT#$COIN_HOME#g'' /etc/systemd/system/${COIN}.service

	#
	# Move Blockchain to User
	/bin/mv ${COIN_ROOT} ${HOME}

	#
	# Set Permissions
	/bin/chown -R -f ${COIN}:root ${HOME}
	/bin/chmod 770 ${HOME} -R

	#
	# Install Raspian Desktop
	# https://www.raspberrypi.org/forums/viewtopic.php?f=66&t=133691

	apt-get install --no-install-recommends xserver-xorg -y
	apt-get install raspberrypi-ui-mods -y
	apt-get install chromium-browser -y 
	apt-get install xrdp -y

	#
	# Set the GPU Mem for GUI (The default is 64 MB but we have enough memory)
	sed -i 's/gpu_mem=16/gpu_mem=256/' /boot/config.txt

	#
	# Set HDMI Mode
	echo "hdmi_enable_4kp60=1" >> /boot/config.txt
	sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/' /boot/config.txt
	sed -i 's/dtoverlay=vc4-fkms-v3d/#dtoverlay=vc4-fkms-v3d/' /boot/config.txt

	#
	# Set resolution to 1080p 60Hz
	sed -i 's/#hdmi_group=1/hdmi_group=2/' /boot/config.txt
	sed -i 's/#hdmi_mode=1/hdmi_mode=82/' /boot/config.txt

	# Set Boot in to GUI with Login
	#sed -i 's/$/ quiet splash plymouth.ignore-serial-consoles/' /boot/cmdline.txt
	#
	
	# Passwordchange next login (only console)
	#chage -d 0 ${COIN}

	echo "
		${COIN_NAME} is installed. Thanks for your support :-)


		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		!!! Please change the password !!!
		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

		User: ${COIN}  Password: ${COIN}
		External IP: ${COIN_EXTERNALIP}:${COIN_PORT}" > ${HOME}info.txt

	cat ${HOME}info.txt

	echo "reboot in 60 sec for the last step ..."

	#
	# Prepare the next script
	/usr/bin/crontab -u root -r
	/usr/bin/crontab -u root -l | { cat; echo "@reboot		${SCRIPT_DIR}${SCRIPT_NAME_NEXT} >${LOG_DIR}${LOG_FILE_NEXT} 2>&1"; } | crontab -


}


	#
	# Is the service installed ?

if [ -f /boot/${COIN}service ]; then

	echo "Previous ${COIN_NAME} detected. Install aborted."

else

	if [ -f /boot/${COIN}setup ]; then

		make_db
		make_coin
		configure_coin_conf
		config_ufw
		config_fail2ban
		swap_off
		configure_service
		checkrunning
		watch_synch
		finish

	else

	echo "Starting installation now..."
	sleep 3
	clear

	start
	app_install
	manage_swap
	reduce_gpu_mem
	disable_bluetooth
	set_network
	set_accounts
	prepair_system
	prepair_crontab
	restart_pi

	fi

fi

sleep 60
/sbin/reboot
