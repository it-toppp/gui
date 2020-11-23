#!/bin/bash
#IPOLD=$1
#IPNEW=$2
IPOLD=$(ls /usr/local/*/data/ips)
IPNEW=$(wget -O - -q ifconfig.me)
grep -rl $1 /etc /usr/local/ /home/*/conf | xargs perl -p -i -e 's/$1/$2/g' 
mv /usr/local/*/data/ips/$1 /usr/local/*/data/ips/$2
mv /etc/apache2/conf.d/$1.conf /etc/apache2/conf.d/$2.conf
mv /etc/nginx/conf.d/$1.conf /etc/nginx/conf.d/$2.conf
v-rebuild-user admin
echo changed
