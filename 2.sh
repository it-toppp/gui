#!/bin/bash

rm -Rfv /etc/yum.repos.d/CentOS-Vault.repo &> /dev/null

curl -O http://vestacp.com/pub/vst-install.sh && bash vst-install.sh --nginx yes --apache yes --phpfpm no --named yes --remi yes --vsftpd yes --proftpd no --iptables yes --fail2ban yes --quota no --exim yes --dovecot yes --spamassassin no --clamav no --softaculous no --mysql yes --postgresql no

echo Installation will take about 5 minutes ...

rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro &> /dev/null
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm &> /dev/null
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

yum install ffmpeg ffmpeg-devel nano mc htop atop iftop lsof bzip2 traceroute gdisk php74-php-curl php74-php-mbstring  php74-php-xml php74-php-gd php74-php-fileinfo php74-php-exif php74-php-intl php74-php-zip php74-php-mysqli php74-php-curl php74-php-ctype php74-php-openssl php74-php-pdo php74-php-opcache php74-php-simplexml php74-php-mysql php72-php-mbstring php72-php-xml php72-php-gd php72-php-fileinfo php72-php-intl php72-php-zip php72-php-mysqli php72-php-curl php72-php-ctype php72-php-openssl php72-php-pdo php72-php-exif php72-php-opcache php72-php-simplexml php72-php-mysql php72-php-curl php74-php-xdebug php73-php-xdebug php72-php-xdebug php70-php-xdebug php72-php-soap php73-php-soap php74-php-soap -y &> /dev/null

wget https://raw.githubusercontent.com/Skamasle/sk-php-selector/master/sk-php-selector2.sh &> /dev/null
chmod +x sk-php-selector2.sh && bash sk-php-selector2.sh php70 php71 php72 php73 &> /dev/null

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
HERE

systemctl restart httpd 1>/dev/null
echo "Fix PHP and HTTPD successfully"

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

echo "Full installation completed [ OK ]"

