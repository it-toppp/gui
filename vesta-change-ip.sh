#!/bin/bash
#IPOLD=$1
#IPNEW=$2
IPOLD=$(ls /usr/local/*/data/ips)
IPNEW=$(wget -O - -q ifconfig.me)
grep -rl $IPOLD /etc /usr/local/ /home/*/conf | xargs perl -p -i -e 's/'"$IPOLD"'/'"$IPNEW"'/g' 
if [ ! -d " /etc/httpd" ]; then
    mv -f /etc/apache2/conf.d/$IPOLD.conf /etc/apache2/conf.d/$IPNEW.conf
    mv -f /usr/local/hestia/data/ips/$IPOLD /usr/local/hestia/data/ips/$IPNEW
fi
mv -f /usr/local/vesta/data/ips/$IPOLD /usr/local/vesta/data/ips/$IPNEW
mv -f /etc/httpd/conf.d/$IPOLD.conf /etc/httpd/conf.d/$IPNEW.conf
mv -f /etc/nginx/conf.d/$IPOLD.conf /etc/nginx/conf.d/$IPNEW.conf
#v-rebuild-user admin
echo changed
