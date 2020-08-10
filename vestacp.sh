#!/bin/bash

PASSWD=$(openssl rand -base64 12)
DOMAIN=$1

rm -Rfv /etc/yum.repos.d/CentOS-Vault.repo &> /dev/null
echo $DOMAIN $PASSWDD
echo $PASSWDD
hostnamectl set-hostname $DOMAIN
pause 20
curl -O http://vestacp.com/pub/vst-install.sh && bash vst-install.sh --nginx yes --apache yes --phpfpm no --named yes --remi yes --vsftpd yes --proftpd no --iptables yes --fail2ban yes --quota no --exim yes --dovecot yes --spamassassin no --clamav no --softaculous no --mysql yes --postgresql no -hostname $DOMAIN --email admin@$DOMAIN --password $PASSWD

echo Installation will take about 5 minutes ...

#rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro &> /dev/null
#rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm &> /dev/null
#yum install http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
#systemctl stop firewalld.service && /bin/systemctl disable firewalld.service 

cat > /etc/yum.repos.d/mariadb.repo << HERE 
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
HERE

systemctl stop mariadb 1>/dev/null
yum remove mariadb mariadb-server -y 1>/dev/null
yum install MariaDB-server MariaDB-client -y &> /dev/null
systemctl start mariadb 1>/dev/null
systemctl enable mariadb &> /dev/null
mysql_upgrade 1>/dev/null

#PMA
#wget https://files.phpmyadmin.net/phpMyAdmin/4.9.5/phpMyAdmin-4.9.5-all-languages.zip
#unzip phpMyAdmin-4.9.5-all-languages.zip
#rm -Rfv phpMyAdmin-4.9.5-all-languages.zip
#rm -Rfv /usr/share/phpMyAdmin
#mv phpMyAdmin-4.9.5-all-languages /usr/share/phpMyAdmin

cat >/etc/my.cnf << HERE 
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
performance-schema=0
innodb_file_per_table=1
innodb_buffer_pool_size=134217728
max_allowed_packet=268435456
open_files_limit=2048
innodb_buffer_pool_size=4000M
sql_mode=NO_ENGINE_SUBSTITUTION
default-storage-engine=MyISAM
max_connections = 5000000
#innodb_use_native_aio = 0
innodb_file_per_table
#slow_query_log=1
#slow_query_log_file=/var/log/mysql-slow-queries.log
[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid
!includedir /etc/my.cnf.d
HERE
systemctl restart mariadb 1>/dev/null
echo "Fix MYSQL successfully"

yum -y install -y gcc-c++ make
curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash -
yum -y install nodejs
yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm -y &> /dev/null
yum install ffmpeg ffmpeg-devel nano git mc htop atop iftop lsof bzip2 traceroute gdisk -y &> /dev/null
yum install php74-php-curl php74-php-mbstring  php74-php-xml php74-php-gd php74-php-fileinfo php74-php-exif php74-php-intl php74-php-zip php74-php-mysqli php74-php-curl php74-php-ctype php74-php-openssl php74-php-pdo php74-php-opcache php74-php-simplexml php74-php-mysql php74-php-soap php74-php-xdebug -y &> /dev/null
yum install php72-php-mbstring php72-php-xml php72-php-gd php72-php-fileinfo php72-php-intl php72-php-zip php72-php-mysqli php72-php-curl php72-php-ctype php72-php-openssl php72-php-pdo php72-php-exif php72-php-opcache php72-php-simplexml php72-php-mysql php72-php-curl php72-php-xdebug php72-php-soap -y &> /dev/null
yum install php73-php-curl php73-php-mbstring  php73-php-xml php73-php-gd php73-php-fileinfo php73-php-exif php73-php-zip php73-php-mysqli php73-php-curl php73-php-ctype php73-php-openssl php73-php-soap php73-php-intl php73-php-pdo php73-php-opcache php73-php-simplexml php73-php-mysql php73-php-xdebug -y &> /dev/null

wget https://raw.githubusercontent.com/it-toppp/sk-php-selector/master/sk-php-selector2.sh &> /dev/null
chmod +x sk-php-selector2.sh && bash sk-php-selector2.sh php70 php71 php72 php73 &> /dev/null
mv /etc/httpd/conf.modules.d/15-php73-php.conf /etc/httpd/conf.modules.d/14-php73-php.conf 

wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar zxf ioncube_loaders_lin_x86-64.tar.gz 
mv ioncube /usr/local 

cat >>/etc/httpd/conf.d/fcgid.conf << HERE 
FcgidBusyTimeout 72000
FcgidIOTimeout 72000
IPCCommTimeout 72000
MaxRequestLen 320000000000
FcgidMaxRequestLen 320000000000
HERE

cat >>/etc/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
post_max_size = 2024M
upload_max_filesize = 2024M
output_buffering = Off
max_execution_time = 6000
max_input_vars = 3000
max_input_time = 6000
zlib.output_compression = Off
memory_limit = 1000M
HERE

cat >>/etc/opt/remi/php70/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
post_max_size = 2024M
upload_max_filesize = 2024M
output_buffering = Off
max_execution_time = 6000
max_input_vars = 3000
max_input_time = 6000
zlib.output_compression = Off
memory_limit = 1000M
[Zend Modules]
zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.0.so
zend_extension_ts = /usr/local/ioncube/ioncube_loader_lin_7.0_ts.so
HERE

cat >>/etc/opt/remi/php71/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
post_max_size = 2024M
upload_max_filesize = 2024M
output_buffering = Off
max_execution_time = 6000
max_input_vars = 3000
max_input_time = 6000
zlib.output_compression = Off
memory_limit = 1000M
[Zend Modules]
zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.1.so
zend_extension_ts = /usr/local/ioncube/ioncube_loader_lin_7.1_ts.so
HERE

cat >>/etc/opt/remi/php72/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
post_max_size = 2024M
upload_max_filesize = 2024M
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

cat >>/etc/opt/remi/php73/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
post_max_size = 2024M
upload_max_filesize = 2024M
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

systemctl restart httpd 1>/dev/null
echo "Fix PHP and HTTPD successfully"

echo "Fix PMA successfully"
#nginx
sed -i 's|client_max_body_size            256m|client_max_body_size            2048m|' /etc/nginx/nginx.conf
sed -i 's|worker_connections  1024;|worker_connections  2024;|' /etc/nginx/nginx.conf
sed -i 's|send_timeout                    30;|send_timeout                    3000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_connect_timeout   90|proxy_connect_timeout   9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_send_timeout  90|proxy_send_timeout  9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_read_timeout  90|proxy_read_timeout  9000|' /etc/nginx/nginx.conf
systemctl restart nginx 1>/dev/null
echo "Fix NGINX successfully"

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

cat >/etc/yum.repos.d/city-fan.repo << HERE 
[CityFan]
name=City Fan Repo
baseurl=http://www.city-fan.org/ftp/contrib/yum-repo/rhel\$releasever/\$basearch/
enabled=1
gpgcheck=0
HERE

yum install curl -y 1>/dev/null

#EXIM
wget https://ca1.dynanode.net/exim-4.93-3.el7.x86_64.rpm
rpm -Uvh --oldpackage exim-4.93-3.el7.x86_64.rpm
systemctl restart exim

echo "Full installation completed [ OK ]"

if [ ! -f "/home/$user/conf/web/ssl.$domain.pem" ]; then
    /usr/local/vesta/binv-add-letsencrypt-domain admin "$DOMAIN" "" "yes"
fi

/usr/local/vesta/binv-add-database admin def def $PASSWD mysql

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
cd /home/admin/web/$DOMAIN/public_html/ && wget http://ss.ultahost.com/playtube.zip
rm -Rfv robots.txt index.html && unzip playtube.zip && rm -Rfv __MACOSX playtube.zip
chmod -R 777 config.php upload assets/import/ffmpeg/ffmpeg nodejs/config.json && 
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
#/usr/local/vesta/bin/v-add-database admin playtube playtube $PASSWDDB mysql
#mysql -uadmin_playtube -p$PASSWDDB admin_playtube < playtube.sql
chown -R admin:admin /home/admin/web
echo "  installation complete"
;;
2)
cd /home/admin/web/$DOMAIN/public_html/ && rm -Rfv robots.txt index.html
wget http://ss.ultahost.com/wowonder.zip  && unzip wowonder.zip && rm -Rfv __MACOSX wowonder.zip && chmod -R 777 cache upload config.php && chown -R admin:admin /home/admin/web
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
3)
cd /home/admin/web/$DOMAIN/public_html/ && rm -Rfv robots.txt index.html
wget http://ss.ultahost.com/deepsound.zip && unzip deepsound.zip && rm -Rfv __MACOSX deepsound.zip  && chmod -R 777 upload config.php ffmpeg/ffmpeg && chown -R admin:admin /home/admin/web
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
4)
cd /home/admin/web/$DOMAIN/public_html/ && rm -Rfv robots.txt index.html
wget http://ss.ultahost.com/quickdate.zip && unzip quickdate.zip && rm -Rfv __MACOSX quickdate.zip && chmod -R 777 upload cache config.php ffmpeg/ffmpeg && chown -R admin:admin /home/admin/web
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
5)
cd /home/admin/web/$DOMAIN/public_html/
wget http://ss.ultahost.com/pixelphoto.zip
rm -Rfv robots.txt index.html && unzip pixelphoto.zip && rm -Rfv __MACOSX pixelphoto.zip 
chmod -R 777 sys/config.php sys/ffmpeg/ffmpeg && chown -R admin:admin /home/admin/web
sed -i 's|domain.com|'$DOMAIN'/|' .htaccess
echo "  installation complete"
;;
6)
echo "  OK"
;;
esac

# Sending notification to admin email
echo -e "Congratulations, you have just successfully installed \
Vesta Control Panel

    https://$DOMAIN:8083
    username: admin
    password: $PASSWD
    
# Sending notification to admin email
echo -e "Congratulations, you have just successfully installed \
Vesta Control Panel

https://$DOMAIN:8083
username: admin
password: $PASSWD
    
Filemanager:
https://$DOMAIN:8083/list/directory/?dir_a=/home/admin/web/$DOMAIN/public_html&dir_b=/home/admin

FTP:
host: $DOMAIN
port: 21
username: admin
password: $PASSWD

phpMyAdmin:
https://$DOMAIN/phpmyadmin
username = root
grep pass /root/.my.cnf
"



