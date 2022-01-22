#!/bin/bash

NC='\033[0m' # No Color
GREEN='\033[0;32m'
CYAN='\033[1;36m'
RED='\033[0;31m'

# Add any apt based package installs under this function
apt-install() {
	printf "\n${GREEN}[+]${NC} ${CYAN}RUNNING APT INSTALLS ${NC} \n\n"
	apt update && apt upgrade -y
	apt install conky-all python3-pip vim net-tools openssh-server gnome-tweaks libtinfo5 libreadline5 -y
}

# Add any snap based package installs under this function
snap-install() {
	printf "\n${GREEN}[+]${NC} ${CYAN}RUNNING SNAP INSTALLS ${NC} \n\n"
	snap install --classic code
	snap install chromium
}

# Add any pip based package installs under this function
pip-install() {
	printf "\n${GREEN}[+]${NC} ${CYAN}RUNNING PIP INSTALLS ${NC} \n\n"
	pip install virtualenv setuptools wheel six python-dateutil
}

# Install Docker and docker-compose
docker-install() {
	printf "\n${GREEN}[+]${NC} ${CYAN}INSTALLING DOCKER AND DOCKER-COMPOSE ${NC}\n\n"
	apt install ca-certificates curl gnupg lsb-release -y
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	apt update
    apt install docker-ce docker-ce-cli containerd.io -y
	apt install docker-compose -y
}

pcte-prep() {
	FILE="lib/linuxinit.sh"
	printf "\n${GREEN}[+]${NC} ${CYAN}RUNNING PCTE PREP ${NC}\n\n"
	chmod +x "$FILE"
	./$FILE
	ln -s /opt/puppetlabs/bin/puppet /usr/bin/puppet
}

# Set conky to autostart and move config to location if necessary
conky-setup() {
	printf "\n${GREEN}[+]${NC} ${CYAN}SETTING CONKY TO AUTOSTART AND COPYING FILES ${NC}\n\n"
	CONFIG="lib/.conkyrc"
	FILE=/home/$SUDO_USER/.config/autostart/conky.desktop
	DIR=/home/$SUDO_USER/.config/autostart/
	if test -f "$FILE" ; then
		printf "\n${GREEN}Conky already configured!, skipping...${NC}\n\n"
	else
		if ! test -f "$CONFIG" ; then
			printf "\n${RED}Conky config missing, skipping...${NC}\n\n"
		else
			if ! test -f /home/$SUDO_USER/.conkyrc ; then
				cp $CONFIG /home/$SUDO_USER/.conkyrc
			else
				printf "\n${RED}Conky config already present in home directory, skipping...${NC}\n\n"
			fi
			if ! test -d "$DIR" ; then
				mkdir -p $DIR
				chown $SUDO_USER $DIR
			else
				printf "\n${RED}${DIR} already present, skipping create...${NC}\n\n"
			fi
			if ! test -f "$FILE" ; then
				touch $FILE
				chown $SUDO_USER $FILE
				echo -e "[Desktop Entry]\nType=Application\nExec=conky\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=Conky\nName=Conky\nComment[en_US]=\nComment=" >> $FILE
			else
				printf "\n${RED}${FILE} already present, skipping create...${NC}\n\n"
			fi
		fi
	fi
}

reboot-prompt() {
	while true; do
		read -p $'\n\e[33mRestart is recommended. Do you wish to reboot now? \e[0m: ' yn
		case $yn in
			[Yy]* ) reboot now; break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

if [ ! "$(whoami)" = "root" ] ; then
	printf "\n${RED}Please run this with sudo... ${NC}\n\n"
	exit 1
fi

apt-install
docker-install
snap-install
pip-install
pcte-prep
conky-setup
reboot-prompt
