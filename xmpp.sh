#!/bin/bash
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
sysctl -p

apt-get install fail2ban -y

cat > /etc/fail2ban/jail.local << HERE
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
HERE

apt install tor prosody -y

printf "HiddenServiceDir /var/lib/tor/jabber\nHiddenServicePort 5222 127.0.0.1:5222\n" | sudo tee /etc/tor/torrc
systemctl  restart tor
sleep 5
MYONION=$(cat /var/lib/tor/jabber/hostname)

cat >/etc/prosody/prosody.cfg.lua << HERE 

admins = { "root@$MYONION" }
modules_enabled = {

	-- Generally required
		"roster"; -- Allow users to have a roster. Recommended ;)
		"saslauth"; -- Authentication for clients and servers. Recommended if you want to log in.
		"tls"; -- Add support for secure TLS on c2s/s2s connections
		-- "dialback"; -- s2s dialback support
		"disco"; -- Service discovery

	-- Not essential, but recommended
		"private"; -- Private XML storage (for room bookmarks, etc.)
		"vcard"; -- Allow users to set vCards
	
	-- These are commented by default as they have a performance impact
		--"privacy"; -- Support privacy lists
		--"compression"; -- Stream compression (Debian: requires lua-zlib module to work)

	-- Nice to have
		"version"; -- Replies to server version requests
		"uptime"; -- Report how long server has been running
		"time"; -- Let others know the time here on this server
		"ping"; -- Replies to XMPP pings with pongs
		"pep"; -- Enables users to publish their mood, activity, playing music and more
		-- "register"; -- Allow users to register on this server using a client and change passwords

	-- Admin interfaces
		-- "admin_adhoc"; -- Allows administration via an XMPP client that supports ad-hoc commands
		--"admin_telnet"; -- Opens telnet console interface on localhost port 5582
	
	-- HTTP modules
		--"bosh"; -- Enable BOSH clients, aka "Jabber over HTTP"
		--"http_files"; -- Serve static files from a directory over HTTP

	-- Other specific functionality
		"posix"; -- POSIX functionality, sends server to background, enables syslog, etc.
		--"groups"; -- Shared roster support
		--"announce"; -- Send announcement to all online users
		--"welcome"; -- Welcome users who register accounts
		--"watchregistrations"; -- Alert admins of registrations
		--"motd"; -- Send a message to users when they log in
		--"legacyauth"; -- Legacy authentication. Only used by some old clients and bots.
};

modules_disabled = {
	-- "offline"; -- Store offline messages
	-- "c2s"; -- Handle client connections
	"s2s"; -- Handle server-to-server connections
};

allow_registration = false;

daemonize = true;

pidfile = "/var/run/prosody/prosody.pid";

c2s_require_encryption = true 

authentication = "internal_hashed"

log = {
	-- Log files (change 'info' to 'debug' for debug logs):
	info = "/dev/null";
	error = "/dev/null";
	-- Syslog:
	{ levels = { "error" }; to = "syslog";  };
}

VirtualHost "$MYONION"
	enabled = true -- Remove this line to enable this host

	ssl = {
		key = "/etc/prosody/certs/host.key";
		certificate = "/etc/prosody/certs/host.crt";
	}

Include "conf.d/*.cfg.lua"
HERE

echo  "create crt for domain $MYONION"
openssl req -new -x509 -days 365 -nodes -out "/etc/prosody/certs/host.crt" -newkey rsa:2048 -keyout "/etc/prosody/certs/host.key" -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=$MYONION"
chmod 644 /etc/prosody/certs/*
systemctl restart prosody
#user create
echo  create accaunt admin@$MYONION
prosodyctl register admin $MYONION 
ufw allow 22
ufw allow 9050
ufw enable
