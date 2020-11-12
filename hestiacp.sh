#!/bin/bash
#apt update &>/dev/null
#apt install curl &>/dev/null
DOMAIN=$1
PASSWD=$2
#if [ -z "$1" ]
#PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\%\^\&\(\)-+= < /dev/urandom | head -c 12)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(echo $DOMAIN | tr -dc "a-z" | cut -c 1-5)
IP=$(wget -O - -q ifconfig.me)
DIG_IP=$(getent ahostsv4 $DOMAIN | sed -n 's/ *STREAM.*//p')

#Prepare
hostnamectl set-hostname $DOMAIN
touch /etc/apt/sources.list.d/mariadb.list
chattr +a /etc/apt/sources.list.d/mariadb.list

wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
bash hst-install.sh --multiphp yes --clamav no --interactive no --hostname $DOMAIN --email admin@$DOMAIN --password $PASSWD 
eval "$(exec /usr/bin/env -i "${SHELL}" -l -c "export")"

#if [ "$DIG_IP" = "$IP" ]; then echo  "DNS lookup for $DOMAIN resolved to $DIG_IP, enabled ssl"
#/usr/local/vesta/bin/v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN "yes"
#fi

v-change-sys-hostname $DOMAIN
v-add-letsencrypt-host
v-add-web-domain-alias admin $DOMAIN www.$DOMAIN
v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN
v-add-dns-domain admin $DOMAIN $IP
v-add-mail-domain admin $DOMAIN
v-delete-mail-domain-antivirus admin $DOMAIN
v-delete-mail-domain-dkim admin $DOMAIN
v-add-mail-account admin $DOMAIN admin $PASSWD
v-add-mail-account admin $DOMAIN info $PASSWD
v-add-database admin $DB $DB $DBPASSWD
sed -i "s|BACKUPS='1'|BACKUPS='3'|" /usr/local/hestia/data/packages/default.pkg
sed -i "s|BACKUPS='1'|BACKUPS='3'|" /usr/local/hestia/data/users/admin/user.conf

#FIX FM
grep -rl "directoryPerm = 0744" /usr/local/hestia/web/fm/vendor/league/flysystem-sftp | xargs perl -p -i -e 's/directoryPerm = 0744/directoryPerm = 0755/g'
grep -rl  "_time] = 300" /usr/local/hestia/php/etc/ | xargs perl -p -i -e 's/_time] = 300/_time] = 1200/g'
mv /usr/local/hestia/web/fm/configuration.php /usr/local/hestia/web/fm/configuration.php_
wget https://raw.githubusercontent.com/hestiacp/hestiacp/main/install/deb/filemanager/filegator/configuration.php -O /usr/local/hestia/web/fm/configuration.php
systemctl restart hestia

wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar zxf ioncube_loaders_lin_x86-64.tar.gz 
mv ioncube /usr/local 

#mysql
sed -i 's|max_connections=200|max_connections=2000|' /etc/mysql/my.cnf
sed -i 's|max_user_connections=50|max_user_connections=500|' /etc/mysql/my.cnf
sed -i 's|wait_timeout=10|wait_timeout=10000|' /etc/mysql/my.cnf
sed -i 's|#innodb_use_native_aio = 0|sql_mode=NO_ENGINE_SUBSTITUTION|' /etc/mysql/my.cnf
systemctl restart  mysql 1>/dev/null
echo "Fix MYSQL successfully"

#PHP
grep -rl  "pm.max_children = 8" /etc/php /usr/local/vesta/data/templates/web/ | xargs perl -p -i -e 's/pm.max_children = 8/pm.max_children = 100/g'

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
[Zend Modules]
zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.4.so
zend_extension_ts = /usr/local/ioncube/ioncube_loader_lin_7.4_ts.so
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
[Zend Modules]
zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.3.so
zend_extension_ts = /usr/local/ioncube/ioncube_loader_lin_7.3_ts.so
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
[Zend Modules]
zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.2.so
zend_extension_ts = /usr/local/ioncube/ioncube_loader_lin_7.2_ts.so
HERE
systemctl restart php7.2-fpm
echo "Fix PHP successfully"

#Apache
a2enmod headers
cat > /etc/apache2/mods-enabled/fcgid.conf << HERE 
<IfModule mod_fcgid.c>
  FcgidConnectTimeout 20
  ProxyTimeout 6000
  FcgidBusyTimeout 72000
  FcgidIOTimeout 72000
  IPCCommTimeout 72000
  MaxRequestLen 320000000000
  FcgidMaxRequestLen 320000000000
  <IfModule mod_mime.c>
    AddHandler fcgid-script .fcgi
  </IfModule>
</IfModule>
HERE

cat > /etc/apache2/mods-available/mpm_event.conf << HERE 
<IfModule mpm_event_module>
StartServers  2
MinSpareThreads  25
MaxSpareThreads 75
ThreadLimit 64
ThreadsPerChild 25
ServerLimit       200
MaxRequestWorkers 200
MaxConnectionsPerChild 0
</IfModule>

HERE
systemctl restart apache2  1>/dev/null

#nginx
sed -i 's|worker_connections  2024;|worker_connections  4048;|' /etc/nginx/nginx.conf
sed -i 's|client_max_body_size            256m|client_max_body_size  5120m|' /etc/nginx/nginx.conf
sed -i 's|worker_connections  1024;|worker_connections  2024;|' /etc/nginx/nginx.conf
sed -i 's|send_timeout                    60;|send_timeout  3000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_connect_timeout           30|proxy_connect_timeout   9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_send_timeout              180|proxy_send_timeout  9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_read_timeout              300|proxy_read_timeout  9000|' /etc/nginx/nginx.conf
systemctl restart nginx 1>/dev/null
echo "Fix NGINX successfully"

#DEB (ffmpeg,node)
apt-get install -y ffmpeg 1>/dev/null
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y nodejs htop 1>/dev/null

#SWAP
wget https://raw.githubusercontent.com/it-toppp/Swap/master/swap.sh -O swap && sh swap 2048

echo "Full installation completed [ OK ]"

#SITE
echo "Which script use?"
echo "   1) WOWONDER"
echo "   2) PLAYTUBE"
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
cd /home/admin/web/$DOMAIN/public_html
wget http://ss.ultahost.com/wowonder.zip && unzip -qo wowonder.zip && chmod -R 777 cache upload config.php && chown -R admin:admin ./
rm -Rfv __MACOSX wowonder.zip index.html &> /dev/null
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
chown -R admin:admin /home/admin/web
echo "  installation complete"
;;
2)
cd /home/admin/web/$DOMAIN/public_html
wget http://ss.ultahost.com/playtube.zip && unzip -qo playtube.zip && chmod -R 777 config.php upload assets/import/ffmpeg/ffmpeg nodejs/config.json && chown -R admin:admin ./
rm -Rfv __MACOSX playtube.zip index.html &> /dev/null
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
3)
cd /home/admin/web/$DOMAIN/public_html
wget http://ss.ultahost.com/deepsound.zip && unzip -qo deepsound.zip && chmod -R 777 upload config.php ffmpeg/ffmpeg && chown -R admin:admin ./
rm -Rfv __MACOSX deepsound.zip index.html &> /dev/null
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
4)
cd /home/admin/web/$DOMAIN/public_html
wget http://ss.ultahost.com/quickdate.zip && unzip -qo quickdate.zip && chmod -R 777 upload cache config.php ffmpeg/ffmpeg && chown -R admin:admin ./
rm -Rfv __MACOSX quickdate.zip index.html &> /dev/null
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
5)
cd /home/admin/web/$DOMAIN/public_html
wget http://ss.ultahost.com/pixelphoto.zip && unzip -qo pixelphoto.zip && chmod -R 777 sys/config.php sys/ffmpeg/ffmpeg && chown -R admin:admin ./
rm -Rfv __MACOSX pixelphoto.zip index.html &> /dev/null
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess 
echo "  installation complete"
;;
6)
echo "  OK"
;;
esac

# Sending notification to admin email
tmpfile=$(mktemp -p /tmp)
chown admin:www-data /home/admin/web/$DOMAIN/public_html

echo '======================================================='
echo -e "Installation is complete:
    https://$DOMAIN
    username: admin
    password: $DBPASSWD
    
Vesta Control Panel:
    https://$DOMAIN:8083
    username: admin
    password: $PASSWD
    
DB:
   db_name: admin_$DB
   db_user: admin_$DB
   db_pass: $DBPASSWD
   
phpMyAdmin:
   http://$IP/phpmyadmin
   username=root
   $(grep pass /root/.my.cnf | tr --delete \')
   
FTP:
   host: $IP
   port: 21
   username: admin
   password: $PASSWD
   
SSH:
   host: $IP
   username: root
   password: $PASSWD
 
"
echo rm -r /home/admin/web/$DOMAIN/public_html/install
echo $PASSWD >  /root/.admin

