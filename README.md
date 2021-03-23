# PI_HoboNickels
## HoboNickels for Raspberry Pi 4 (4GB or 8GB RAM Version only) with Desktop RPD and remonte SSH/RDP control.

Needs:

+ ISO Raspbian Lite (https://www.raspberrypi.org/software/operating-systems/#raspberry-pi-os-32-bit)
+ 16GB SD-Card
+ A Raspberry Pi 4 (with minimum 4GB Ram)
+ Login as ROOT (start Raspberry Pi and login as 'pi' user... password is 'raspberry'... 'sudo su root')

You can execute the following install script. Just copy/paste and hit "Enter"-key.
```
wget -qO - https://raw.githubusercontent.com/SpecTurrican/PI_HoboNickels/master/setup.sh | bash
```
The installation goes into the background. You can follow the installation with :
```
sudo tail -f /root/PI_HoboNickels/logfiles/start.log  # 1. Phase "Prepar the system"
sudo tail -f /root/PI_HoboNickels/logfiles/make.log   # 2. Phase "Compiling"
sudo tail -f /root/PI_HoboNickels/logfiles/config_desktop.log   # 3. Phase "Configuration of the HoboNickels user interface"
```
The installation takes about 4 hours.
The Raspberry Pi is restarted 3 times during the installation.
After the installation the following user and password is valid :
```
hobonickels
```
Please change your password !!!

You can with RDP (on Windows "mstsc") or via HDMI start the HoboNickels QT on the Desktop.

In the File "info.txt" on your Desktop is yours External IP.

You need only the console ?

Start the service with:
```
sudo systemctl enable hobonickels.service
```

If everything worked out, you can retrieve the status with the following command :
```
hobonickelsd getinfo             # general information
hobonickelsd help                # list of commands
```
## Configfile
The configfile for hobonickels is stored in:
```
/home/hobonickels/.HoboNickels/HoboNickels.conf
```
Settings during installation:
```
rpcuser=hobonickelspixxxxxxxxx                 # x=random
rpcpassword=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # x=random
rpcallowip=127.0.0.1
port=7372
rpcport=7373
server=1
listen=1
daemon=1
maxconnections=24
logtimestamps=1
txindex=0
externalip="Your IPv4 adress":7372

#############
# NODE LIST #
#############
addnode=add a node from https://chainz.cryptoid.info/hbn/api.dws?q=nodes list
...
```
## Security
- You have a Firewall or Router ? Please open the Port 7372 for your raspberry pi. Thanks!
- fail2ban is configured with 24 hours banntime. (https://www.fail2ban.org/wiki/index.php/Main_Page)
- ufw service open ports is 22 (SSH), 3389 (RDP) and 7372 (HoboNickels). (https://help.ubuntu.com/community/UFW)
## Infos about HoboNickels
[Homepage](http://www.hobonickels.info/) | [Source GitHub](https://github.com/Tranz5/HoboNickels) | [Hobomapinfo](https://hobomap.info/) | [Blockchainexplorer](https://chainz.cryptoid.info/hbn/) | [Discord](https://discord.gg/JendXsA) | [bitcointalk.org](https://bitcointalk.org/index.php?topic=303749.0)

## Screenshoot
![ScreenShot](https://raw.githubusercontent.com/SpecTurrican/PI_HoboNickels/hobonickels_setup/.png?raw=true)

## Have fun and thanks for your support :-)
HBN donate to :
```
Ey4QJpjPiQrbdFEjmiav21i77ozBfMfDtd
```
