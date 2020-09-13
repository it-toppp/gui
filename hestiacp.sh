#!/bin/bash

PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 12)
DOMAIN=$1
IP=$(curl ifconfig.me)
DIG_IP=$(getent ahostsv4 $DOMAIN | sed -n 's/ *STREAM.*//p')

echo $DOMAIN
echo $PASSWDD
hostnamectl set-hostname $DOMAIN
wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
sudo bash hst-install.sh --apache yes --nginx yes --phpfpm yes --multiphp yes --vsftpd yes --proftpd no --named yes --mysql yes --postgresql no --exim yes --dovecot yes --clamav no --spamassassin yes --iptables yes --fail2ban yes --quota no --api yes --force no --interactive no --port 8083 --hostname $DOMAIN --email admin@$DOMAIN --password $PASSWD --lang en

echo Installation will take about 5 minutes ...

#PHP
cat >> /etc/php/7.4/fpm/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
post_max_size = 5120M
upload_max_filesize = 5120M
output_buffering = Off
max_execution_time = 6000
max_input_vars = 3000
max_input_time = 6000
zlib.output_compression = Off
memory_limit = 1000M
HERE
echo "Fix PHP successfully"

cat >> /etc/php/7.3/fpm/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
post_max_size = 5120M
upload_max_filesize = 5120M
output_buffering = Off
max_execution_time = 6000
max_input_vars = 3000
max_input_time = 6000
zlib.output_compression = Off
memory_limit = 1000M
HERE
echo "Fix PHP successfully"

cat >>  /etc/php/7.2/fpm/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
post_max_size = 5120M
upload_max_filesize = 5120M
output_buffering = Off
max_execution_time = 6000
max_input_vars = 3000
max_input_time = 6000
zlib.output_compression = Off
memory_limit = 1000M
HERE
echo "Fix PHP successfully"

#nginx
sed -i 's|client_max_body_size            256m|client_max_body_size  5120m|' /etc/nginx/nginx.conf
sed -i 's|worker_connections  1024;|worker_connections  2024;|' /etc/nginx/nginx.conf
sed -i 's|send_timeout                    60;|send_timeout  3000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_connect_timeout           30|proxy_connect_timeout   9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_send_timeout              180|proxy_send_timeout  9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_read_timeout              300|proxy_read_timeout  9000|' /etc/nginx/nginx.conf
systemctl restart nginx 1>/dev/null
systemctl restart nginx 1>/dev/null
echo "Fix NGINX successfully"

sed -i 's|wait_timeout=10|wait_timeout=10000|' /etc/mysql/my.cnf
systemctl restart  mysql 1>/dev/null
echo "Fix MYSQL successfully"


apt -y install ffmpeg
apt-get install -y nodejs
