#!/bin/bash
DOMAIN=$1
SCRIPT=$2
PURSHCODE=$3

#PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\%\^\&\(\)-+= < /dev/urandom | head -c 12)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 5)
IP=$(wget -O - -q ifconfig.me)

if [ ! -d "/home/admin/web/$DOMAIN/public_html" ]; then
v-add-web-domain admin $DOMAIN $IP yes www.$DOMAIN
v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN
fi
echo "$IP  $DOMAIN" >> /etc/hosts
v-add-database admin $DB $DB $DBPASSWD

if [ "$SCRIPT" = "wowonder-null" ] || [ "$SCRIPT" = "wowonder" ]; then
cd /home/admin/web/$DOMAIN/public_html
rm -fr /home/admin/web/$DOMAIN/public_html/{*,.*}
wget http://ss.ultahost.com/$SCRIPT.zip
unzip -qo $SCRIPT.zip
chmod 777 ffmpeg/ffmpeg upload cache ffmpeg/ffmpeg sys/ffmpeg/ffmpeg ./assets/import/ffmpeg/ffmpeg  &> /dev/null
chown -R admin:admin ./

 if [ "$SCRIPT" = "pixelphoto" ]; then
  mv ./install/index.php ./install/index.php_old
  wget https://raw.githubusercontent.com/it-toppp/ultahost/main/scripts/pixelphoto/installer.php -O ./install/index.php
 fi
 
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
     mysql admin_$DB -e "UPDATE config SET value = 'on' WHERE  name = 'ffmpeg_system';" &> /dev/null
     mysql admin_$DB -e "UPDATE config SET value = '/usr/bin/ffmpeg' WHERE  name = 'ffmpeg_binary_file';" &> /dev/null

  if grep -wqorP $DOMAIN /home/admin/web/$DOMAIN/public_html;
  then
  #  rm -r ./install  __MACOSX $SCRIPT.zip  &> /dev/null
    echo Script $SCRIPT installed
  else
  echo Script $SCRIPT dont installed
  fi
fi

cat > htaccess_tmp << HERE
RewriteCond %{HTTP_HOST} ^www.$DOMAIN [NC]
RewriteRule ^(.*)$ https://$DOMAIN/\$1 [L,R=301]
HERE
sed -i -e '/RewriteEngine/r htaccess_tmp' .htaccess
echo -e "Installation $SCRIPT is complete:
    https://$DOMAIN
    username: admin
    password: $DBPASSWD
"
