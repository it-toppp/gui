#!/bin/bash
echo "Please set SYNAPSE_SERVER_NAME. Example: matrix.domain.com"
read SYNAPSE_DOMAIN
DIG_IP=$(getent hosts $SYNAPSE_DOMAIN | awk '{ print $1 }')
IP=$(curl ifconfig.me)
DB_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

if [ -z "$DIG_IP" ]; then echo Unable to resolve $SYNAPSE_DOMAIN. Installation aborted &&  exit 1
fi
if [ "$DIG_IP" != "$IP" ]; then echo  "DNS lookup for $SYNAPSE_DOMAIN resolved to $DIG_IP but didn't match local $IP. Maybe you are usingn Cloudflare"
   read -p "Continue anyway? [y/N] " -n 1 -r
   echo
   echo   "Installation aborted"
   if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1
   fi
 fi
echo "Please set matrix admin password"
read ADMIN_PASS
echo "Please wait..."
curl -SsL https://get.docker.com | sh &> /dev/null
systemctl start docker && systemctl enable docker 
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose &> /dev/null

docker-compose --file /opt/matrix/docker-compose.yml down &> /dev/null
docker volume rm matrix_matrix &> /dev/null
rm -R /opt/matrix &> /dev/null
rm -R /root/install.sh &> /dev/null

mkdir  -p /opt/matrix/data
cd /opt/matrix
docker run -it --rm \
    --mount type=bind,source="/opt/matrix/data",dst=/data \
    -e SYNAPSE_SERVER_NAME=$SYNAPSE_DOMAIN \
    -e SYNAPSE_REPORT_STATS=yes \
    -e SYNAPSE_NO_TLS=true \
    -e POSTGRES_PASSWORD=$DB_PASSWORD \
    -e SYNAPSE_CONFIG_PATH=/data/homeserver.yaml \
    matrixdotorg/synapse:latest migrate_config

sed -i 's|max_upload_size: "10M"|max_upload_size: "1024M"|' /opt/matrix/data/homeserver.yaml

echo 'Do you wish to enabled registration of new users via Matrix clients? select yn in "Yes" "No"'
read -r -p "Are you sure? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    sed -i 's|enable_registration: False|enable_registration: True|' /opt/matrix/data/homeserver.yaml
    echo registration enabled
else
    echo registration disabled
fi

cat >> /opt/matrix/docker-compose.yml << HERE
version: '3.7'
services:
  traefik:
    container_name: traefik
    image: traefik:v1.7
    command:
      - --api
      - --docker
      - --docker.watch=true
      - --docker.exposedbydefault=false
      - --defaultentrypoints=http,https
      - --entryPoints=Name:http Address::80 Redirect.EntryPoint:https
      - --entryPoints=Name:https Address::443 TLS
      - --acme
      - --acme.acmelogging=true
      - --acme.email=admin@$SYNAPSE_DOMAIN
      - --acme.storage=/letsencrypt/acme.json
      - --acme.entrypoint=https
      - --acme.onhostrule=true
      - --acme.tlsconfig=true
      - --acme.onHostRule=true
      - --acme.httpchallenge.entrypoint=http
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - letsencrypt:/letsencrypt
    labels:
      - "traefik.enable=false"

  admin:
    image: awesometechnologies/synapse-admin
    container_name: admin
    restart: unless-stopped
#    ports:
#      - 12345:80
    depends_on:
      - synapse
    labels:
      - traefik.enable=true
      - traefik.port=80
      - traefik.entryPoint=https
      - traefik.backend=admin
      - traefik.frontend.rule=Host:$SYNAPSE_DOMAIN; PathPrefixStrip:/admin/
  
  riotweb:
    container_name: riotweb
    image: vectorim/riot-web:latest
#    hostname: riotweb
    restart: unless-stopped
    volumes:
      - /opt/matrix/config.json:/app/config.json:ro
    labels:
      - traefik.enable=true
      - traefik.port=80
      - traefik.entryPoint=https
      - traefik.backend=riotweb
      - traefik.frontend.rule=Host:$SYNAPSE_DOMAIN; PathPrefixStrip:/riot/

  synapse:
    image: matrixdotorg/synapse
    container_name: synapse
    restart: unless-stopped
    environment:
      POSTGRES_USER: synapse
      POSTGRES_PASSWORD: $DB_PASSWORD
      POSTGRES_HOST: db
      POSTGRES_DB: synapse
    depends_on:
      - db
    volumes:
      - matrix:/data
    labels:
      - traefik.enable=true
      - traefik.port=8008
      - traefik.entryPoint=https
      - traefik.backend=synapse
      - traefik.frontend.rule=Host:$SYNAPSE_DOMAIN
  
  db:
    image: docker.io/postgres:10-alpine
    container_name: db
    restart: always
    environment:
      - POSTGRES_DB=synapse
      - POSTGRES_USER=synapse
      - POSTGRES_PASSWORD=$DB_PASSWORD
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
      - ./Postgres:/var/lib/postgresql/data
    labels:
      - traefik.enable=false

volumes:
  letsencrypt:
  matrix:
   driver_opts:
     type: none
     device: /opt/matrix/data
     o: bind
HERE

cat >> /opt/matrix/config.json << HERE
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "https://$SYNAPSE_DOMAIN",
            "server_name": "$SYNAPSE_DOMAIN"
        },
        "m.identity_server": {
            "base_url": "https://vector.im"
        }
    },
    "disable_custom_urls": false,
    "disable_guests": false,
    "disable_login_language_selector": false,
    "disable_3pid_login": false,
    "brand": "Riot",
    "integrations_ui_url": "https://scalar.vector.im/",
    "integrations_rest_url": "https://scalar.vector.im/api",
    "integrations_widgets_urls": [
        "https://scalar.vector.im/_matrix/integrations/v1",
        "https://scalar.vector.im/api",
        "https://scalar-staging.vector.im/_matrix/integrations/v1",
        "https://scalar-staging.vector.im/api",
        "https://scalar-staging.riot.im/scalar/api"
    ],
    "integrations_jitsi_widget_url": "https://scalar.vector.im/api/widgets/jitsi.html",
    "bug_report_endpoint_url": "https://riot.im/bugreports/submit",
    "defaultCountryCode": "GB",
    "showLabsSettings": false,
    "features": {
        "feature_pinning": "labs",
        "feature_custom_status": "labs",
        "feature_custom_tags": "labs",
        "feature_state_counters": "labs"
    },
    "default_federate": true,
    "default_theme": "light",
    "roomDirectory": {
        "servers": [
            "matrix.org"
        ]
    },
    "welcomeUserId": "@riot-bot:matrix.org",
    "piwik": {
        "url": "https://piwik.riot.im/",
        "whitelistedHSUrls": ["https://matrix.org"],
        "whitelistedISUrls": ["https://vector.im", "https://matrix.org"],
        "siteId": 1
    },
    "enable_presence_by_hs_url": {
        "https://matrix.org": false,
        "https://matrix-client.matrix.org": false
    },
    "settingDefaults": {
        "breadcrumbs": true
    }
}
HERE

docker-compose --file /opt/matrix/docker-compose.yml up -d
sleep 30
#echo "Please create ferst admin-user:"
docker exec -it synapse register_new_matrix_user -u admin -p $ADMIN_PASS -a -c /data/homeserver.yaml http://localhost:8008
echo "#####################################################################################################################"

echo "Matrix server      :  https://$SYNAPSE_DOMAIN"
echo "RIOT web-cletnt    :  https://$SYNAPSE_DOMAIN/riot/"
echo "Admin web-panel    :  https://$SYNAPSE_DOMAIN/admin/"
echo "user               :  admin"
echo "password           :  $ADMIN_PASS"
