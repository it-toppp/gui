#!/bin/bash
#echo "Enter teamviewer password: "
#read TIMPASS

useradd -G sudo -d /home/bot -m -s /bin/bash bot
passwd bot

sudo apt update
sudo apt install xubuntu-core xrdp firefox mc htop -y

wget https://raw.githubusercontent.com/Cretezy/Swap/master/swap.sh -O swap && sh swap 2G

#wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
#chmod 777 ./teamviewer_amd64.deb
#apt install ./teamviewer_amd64.deb -y
#teamviewer passwd qazwsxedc
#ping 8.8.8.8 -c 10
#teamviewer license accept
#teamviewer info | grep teamviewer ID
#read -n 1 -s -r -p "your password: qazwsxedc        Copy Teamviewer ID   and Press any key to continue"
#reboot
