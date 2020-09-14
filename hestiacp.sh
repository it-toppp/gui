#!/bin/bash
#apt update &>/dev/null
#apt install curl &>/dev/null
DOMAIN=$1
PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 12)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(echo $DOMAIN | tr -dc "a-z" | cut -c 1-5)

IP=$(wget -O - -q ifconfig.me)
DIG_IP=$(getent ahostsv4 $DOMAIN | sed -n 's/ *STREAM.*//p')

hostnamectl set-hostname $DOMAIN
wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install-debian.sh
bash hst-install-debian.sh --multiphp yes --clamav no --interactive no --hostname $DOMAIN --email admin@$DOMAIN --password $PASSWD 
eval "$(exec /usr/bin/env -i "${SHELL}" -l -c "export")"

v-change-sys-hostname $DOMAIN
v-add-letsencrypt-host
v-add-database admin $DB $DB $PASSWD

echo Installation will take about 1 minutes ...

#mysql
sed -i 's|wait_timeout=10|wait_timeout=10000|' /etc/mysql/my.cnf
sed -i 's|#innodb_use_native_aio = 0|sql_mode=NO_ENGINE_SUBSTITUTION|' /etc/mysql/my.cnf
systemctl restart  mysql 1>/dev/null
echo "Fix MYSQL successfully"

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
systemctl restart php7.4-fpm

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
systemctl restart php7.3-fpm

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
systemctl restart php7.2-fpm

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

curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y ffmpeg nodejs 1>/dev/null

#SWAP
wget https://raw.githubusercontent.com/it-toppp/Swap/master/swap.sh -O swap && sh swap 2048

echo "Full installation completed [ OK ]"

#SITE
#if [ "$DIG_IP" = "$IP" ]; then echo  "DNS lookup for $DOMAIN resolved to $DIG_IP, enabled ssl"
#/usr/local/vesta/bin/v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN "yes"
#fi

echo "Which script use?"
echo "   1) PLAYTUBE"
echo "   2) WOWONDER"
echo "   3) DEEPSOUND"
echo "   4) QUICKDATE"
echo "   5) PIXELPHOTO"
echo "   6) OTHER SCRIPT"
    read -p "Protocol [1]: " script
    until [[ -z "$script" || "$script" =~ ^[123456]$ ]]; do
echo "$script: invalid selection."
read -p "Script [1]: " script
    done
    case "$script" in
1|"")
cd /home/admin/web/$DOMAIN/public_html/ && rm -Rfv robots.txt index.html
wget http://ss.ultahost.com/playtube.zip && unzip playtube.zip && chmod -R 777 config.php upload assets/import/ffmpeg/ffmpeg nodejs/config.json
rm -Rfv __MACOSX playtube.zip
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
#/usr/local/vesta/bin/v-add-database admin playtube playtube $PASSWDDB mysql
#mysql -uadmin_playtube -p$PASSWDDB admin_playtube < playtube.sql
chown -R admin:admin /home/admin/web
echo "  installation complete"
;;
2)
cd /home/admin/web/$DOMAIN/public_html/ && rm -Rfv robots.txt index.html
wget http://ss.ultahost.com/wowonder.zip &> /dev/null && unzip wowonder.zip &> /dev/null&& chmod -R 777 cache upload config.php && chown -R admin:admin ./
rm -Rfv __MACOSX wowonder.zip
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
3)
cd /home/admin/web/$DOMAIN/public_html/ && rm -Rfv robots.txt index.html
wget http://ss.ultahost.com/deepsound.zip && unzip deepsound.zip &> /dev/null && chmod -R 777 upload config.php ffmpeg/ffmpeg && chown -R admin:admin ./
rm -Rfv __MACOSX deepsound.zip
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
4)
cd /home/admin/web/$DOMAIN/public_html/ && rm -Rfv robots.txt index.html
wget http://ss.ultahost.com/quickdate.zip && unzip quickdate.zip &> /dev/null && chmod -R 777 upload cache config.php ffmpeg/ffmpeg && chown -R admin:admin ./
rm -Rfv __MACOSX quickdate.zip
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
5)
cd /home/admin/web/$DOMAIN/public_html/ && rm -Rfv robots.txt index.html 
wget http://ss.ultahost.com/pixelphoto.zip && unzip pixelphoto.zip &> /dev/null && chmod -R 777 sys/config.php sys/ffmpeg/ffmpeg && chown -R admin:admin ./
rm -Rfv __MACOSX pixelphoto.zip 
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
6)
echo "  OK"
;;
esac

# Sending notification to admin email
tmpfile=$(mktemp -p /tmp)

echo '======================================================='
echo -e "Installation is complete:
Vesta Control Panel:
    https://$DOMAIN:8083
    username: admin
    password: $PASSWD
    
Filemanager:
   https://$DOMAIN:8083/fm/#/?cd=%2Fweb%2F$DOMAIN%2Fpublic_html
   
DB:
   db_name: admin_$DB
   db_user: admin_$DB
   db_pass: $DBPASSWD
   
phpMyAdmin:
   http://$DOMAIN/phpmyadmin
   username= root
   $(grep pass /root/.my.cnf)
   
FTP:
   host: $IP
   port: 21
   username: admin
   password: $PASSWD
   
SSH:
   host: $IP
   username: root
   password: 
 
"
echo '======================================================='
cat $tmpfile
