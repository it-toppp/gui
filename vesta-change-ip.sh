#!/bin/bash
#IPOLD=$1
#IPNEW=$2
IPOLD=$(ls /usr/local/*/data/ips)
IPNEW=$(wget -O - -q ifconfig.me)
grep -rl $IPOLD /etc /usr/local/ /home/*/conf | xargs perl -p -i -e 's/$IPOLD/$IPNEW/g' 
if [ ! -d " /etc/httpd" ]; then
    mv /etc/apache2/conf.d/$IPOLD.conf /etc/apache2/conf.d/$IPNEW.conf
fi
mv /usr/local/*/data/ips/$IPOLD /usr/local/*/data/ips/$IPNEW
mv /etc/httpd/conf.d/$IPOLD.conf /etc/httpd/conf.d/$IPNEW.conf
mv /etc/nginx/conf.d/$IPOLD.conf /etc/nginx/conf.d/$IPNEW.conf
v-rebuild-user admin
echo changed
