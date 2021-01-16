#!/bin/bash
apt-get update &>/dev/null
#apt install curl &>/dev/null

DOMAIN=$1
PASSWD=$2
SCRIPT=$3
PURSHCODE=$4

#if [ -z "$1" ]
#PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\%\^\&\(\)-+= < /dev/urandom | head -c 12)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(LC_CTYPE=C tr -dc a-z0-9 < /dev/urandom | head -c 5)
#DB=$(echo $DOMAIN | tr -dc "a-z" | cut -c 1-5)
IP=$(wget -O - -q ifconfig.me)
DIG_IP=$(getent ahostsv4 $DOMAIN | sed -n 's/ *STREAM.*//p')

#Prepare
hostnamectl set-hostname $DOMAIN
touch /etc/apt/sources.list.d/mariadb.list
chattr +a /etc/apt/sources.list.d/mariadb.list


wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
bash hst-install.sh --multiphp yes --clamav no --interactive no --hostname $DOMAIN --email admin@$DOMAIN --password $PASSWD 

#if [ "$DIG_IP" = "$IP" ]; then echo  "DNS lookup for $DOMAIN resolved to $DIG_IP, enabled ssl"
#/usr/local/vesta/bin/v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN "yes"
#fi

#DEB (ffmpeg,node)
#apt update 1>/dev/null
apt-get install -y ffmpeg 1>/dev/null
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y nodejs htop 1>/dev/null

eval "$(exec /usr/bin/env -i "${SHELL}" -l -c "export")"
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
#sed -i 's|max_connections=200|max_connections=2000|' /etc/mysql/my.cnf
#sed -i 's|max_user_connections=50|max_user_connections=500|' /etc/mysql/my.cnf
#sed -i 's|wait_timeout=10|wait_timeout=10000|' /etc/mysql/my.cnf
#sed -i 's|#innodb_use_native_aio = 0|sql_mode=NO_ENGINE_SUBSTITUTION|' /etc/mysql/my.cnf
cat > /etc/mysql/conf.d/z_custom.cnf << HERE 
[mysqld]
    query_cache_size = 0
    query_cache_type = 0
    query_cache_limit = 8M
    join_buffer_size = 2M
    table_open_cache = 8192
    table_definition_cache = 1000
    thread_cache_size = 500
    tmp_table_size = 256M
    
    innodb_buffer_pool_size = 1G
    sql_mode = NO_ENGINE_SUBSTITUTION
    
    max_heap_table_size  = 256M
    max_allowed_packet = 1024M
    max_connections = 20000
    max_user_connections = 5000
    wait_timeout = 10000
       
HERE
systemctl restart  mysql 1>/dev/null
echo "Fix MYSQL successfully"

#PHP
grep -rl  "pm.max_children = 8" /etc/php /usr/local/hestia/data/templates/web | xargs perl -p -i -e 's/pm.max_children = 8/pm.max_children = 100/g'

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
ServerLimit       2000
MaxRequestWorkers 2000
MaxConnectionsPerChild 0
</IfModule>
HERE
systemctl restart apache2  1>/dev/null

#nginx
sed -i 's|client_max_body_size            256m|client_max_body_size  5120m|' /etc/nginx/nginx.conf
sed -i 's|worker_connections  1024;|worker_connections  4096;|' /etc/nginx/nginx.conf
sed -i 's|send_timeout                    60;|send_timeout  3000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_connect_timeout           30|proxy_connect_timeout   9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_send_timeout              180|proxy_send_timeout  9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_read_timeout              300|proxy_read_timeout  9000|' /etc/nginx/nginx.conf
systemctl restart nginx 1>/dev/null
echo "Fix NGINX successfully"

#SWAP
wget https://raw.githubusercontent.com/it-toppp/Swap/master/swap.sh -O swap && sh swap 2048

echo "Full installation completed [ OK ]"

#SITE
echo "$IP  $DOMAIN" >> /etc/hosts
#v-add-database admin $DB $DB $DBPASSWD
if [ ! -z "$SCRIPT" ];
then
cd /home/admin/web/$DOMAIN/public_html
rm -fr /home/admin/web/$DOMAIN/public_html/{*,.*}
wget http://ss.ultahost.com/$SCRIPT.zip
unzip -qo $SCRIPT.zip
chmod 777 ffmpeg/ffmpeg upload cache ffmpeg/ffmpeg sys/ffmpeg/ffmpeg ./assets/import/ffmpeg/ffmpeg  &> /dev/null
chown -R admin:admin ./

curl -L --fail --silent --show-error --post301 --insecur \
     --data-urlencode "purshase_code=$PURSHCODE" \
     --data-urlencode "sql_host=localhost" \
     --data-urlencode "sql_user=admin_$DB" \
     --data-urlencode "sql_pass=$DBPASSWD" \
     --data-urlencode "sql_name=admin_$DB" \
     --data-urlencode "site_url=https://$DOMAIN" \
     --data-urlencode "siteName=$DOMAIN" \
     --data-urlencode "siteTitle=$DOMAIN" \
     --data-urlencode "siteEmail=info@$DOMAIN" \
     --data-urlencode "admin_username=admin" \
     --data-urlencode "admin_password=$DBPASSWD" \
     --data-urlencode "install=install" \
     http://$DOMAIN/install/?page=installation | grep -o -e "Failed to connect to MySQL" -e "successfully installed" -e "Wrong purchase code" -e "This code is already used on another domain"
     mysql admin_$DB -e "UPDATE config SET value = 'on' WHERE  name = 'ffmpeg_system';"
     mysql admin_$DB -e "UPDATE config SET value = '/usr/bin/ffmpeg' WHERE  name = 'ffmpeg_binary_file';"
  if grep -wqorP $DOMAIN /home/admin/web/$DOMAIN/public_html;
  then
    rm -r ./install  __MACOSX $SCRIPT.zip  &> /dev/null
  else
    echo Script $SCRIPT dont installed
    echo rm -r /home/admin/web/$DOMAIN/public_html/install
  fi
  #HTACCESS
cat > htaccess_tmp << HERE
RewriteCond %{HTTP_HOST} ^www.$DOMAIN [NC]
RewriteRule ^(.*)$ https://$DOMAIN/\$1 [L,R=301]
HERE
sed -i -e '/RewriteEngine/r htaccess_tmp' .htaccess
rm -f htaccess_tmp
else
 echo Only Panel
fi
chown admin:www-data /home/admin/web/$DOMAIN/public_html

# Sending notification to admin email
tmpfile=$(mktemp -p /tmp)

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
echo $PASSWD >  /root/.admin

