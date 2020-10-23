#!/bin/bash
#apt update &>/dev/null
#apt install curl &>/dev/null
DOMAIN=$1
PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\%\^\&\(\)-+= < /dev/urandom | head -c 12)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(echo $DOMAIN | tr -dc "a-z" | cut -c 1-5)

IP=$(wget -O - -q ifconfig.me)
DIG_IP=$(getent ahostsv4 $DOMAIN | sed -n 's/ *STREAM.*//p')

hostnamectl set-hostname $DOMAIN
wget http://c.myvestacp.com/vst-install-debian.sh
bash vst-install-debian.sh  --clamav no --interactive no --hostname $DOMAIN --email admin@$DOMAIN --password $PASSWD 
eval "$(exec /usr/bin/env -i "${SHELL}" -l -c "export")"

#v-change-sys-hostname $DOMAIN
#v-add-letsencrypt-host
#v-add-mail-domain admin $DOMAIN
v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN
v-change-web-domain-proxy-tpl admin $DOMAIN force-https-webmail-phpmyadmin
v-delete-mail-domain-antivirus admin $DOMAIN
v-delete-mail-domain-dkim admin $DOMAIN
v-add-mail-account admin $DOMAIN admin $PASSWD
v-add-mail-account admin $DOMAIN info $PASSWD
v-add-database admin $DB $DB $DBPASSWD

curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y ffmpeg nodejs 1>/dev/null

#mysql
sed -i 's|wait_timeout=10|wait_timeout=10000|' /etc/mysql/my.cnf
sed -i 's|#innodb_use_native_aio = 0|sql_mode=NO_ENGINE_SUBSTITUTION|' /etc/mysql/my.cnf
systemctl restart  mysql 1>/dev/null
echo "Fix MYSQL successfully"

#PHP
#mv /etc/php/7.3/fpm/pool.d/* /root/
wget https://raw.githubusercontent.com/myvesta/vesta/master/src/deb/for-download/tools/multi-php-install.sh
sed -i 's|inst_72=0|inst_72=1|' multi-php-install.sh
sed -i 's|inst_74=0|inst_74=1|' multi-php-install.sh
bash multi-php-install.sh

grep -rl  "shell_exec," /etc/php /usr/local/vesta | xargs perl -p -i -e 's/shell_exec,//g'

grep -rl  "upload_max_filesize" /etc/php /usr/local/vesta/data/templates | set -e 's/upload_max_filesize/d'
grep -rl  "post_max_size" /etc/php /usr/local/vesta/data/templates | set -e 's/post_max_size/d'
grep -rl  "max_execution_time" /etc/php /usr/local/vesta/data/templates | set -e 's/max_execution_time/d'

#grep -rl  "80M" /etc/php/7.3/fpm/pool.d /usr/local/vesta/data/templates/web/apache2 | xargs perl -p -i -e 's/80M/5000M/g'  
#grep -rl  "_time] = 30" /etc/php/7.3/fpm/pool.d /usr/local/vesta/data/templates/web/apache2 | xargs perl -p -i -e 's/_time] = 30/_time] = 5000/g'

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

#nginx
sed -i 's|client_max_body_size            256m|client_max_body_size  5120m|' /etc/nginx/nginx.conf
sed -i 's|worker_connections  1024;|worker_connections  2024;|' /etc/nginx/nginx.conf
sed -i 's|send_timeout                    30;|send_timeout  3000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_connect_timeout           30|proxy_connect_timeout   9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_send_timeout              180|proxy_send_timeout  9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_read_timeout              300|proxy_read_timeout  9000|' /etc/nginx/nginx.conf
systemctl restart nginx 1>/dev/null
systemctl restart nginx 1>/dev/null
echo "Fix NGINX successfully"

curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y ffmpeg nodejs 1>/dev/null

#EXIM
sed -i 's|  drop    condition     = ${if isip{$sender_helo_name}}|#  drop    condition     = ${if isip{$sender_helo_name}}|' /etc/exim4/exim4.conf.template
sed -i 's|          message       = Access denied - Invalid HELO name (See RFC2821 4.1.3)|#          message       = Access denied - Invalid HELO name (See RFC2821 4.1.3)|' /etc/exim4/exim4.conf.template
systemctl restart exim4

#SWAP
wget https://raw.githubusercontent.com/it-toppp/Swap/master/swap.sh -O swap && sh swap 2048

#VESTA CP FileManager:
cat >> /usr/local/vesta/conf/vesta.conf << HERE 
FILEMANAGER_KEY='mykey'
SFTPJAIL_KEY='mykey'
HERE
sed -i 's|v_host=|#v_host=|' /usr/local/vesta/bin/v-activate-vesta-license
sed -i 's|answer=$(curl -s $v_host/activate.php?licence_key=$license&module=$module)|answer=0|' /usr/local/vesta/bin/v-activate-vesta-license
sed -i 's|check_result|#check_result|' /usr/local/vesta/bin/v-activate-vesta-license
sed -i 's|$BIN/v-check-vesta-license|#$BIN/v-check-vesta-license|' /usr/local/vesta/bin/v-backup-users

echo "Fix VESTACP-FileManager successfully"

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
   http://$DOMAIN/phpmyadmin
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
   password: 
" 
echo '======================================================='
cat $tmpfile
echo rm -r /home/admin/web/$DOMAIN/public_html/install
echo $PASSWD >  /root/.admin
 


