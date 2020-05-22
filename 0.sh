
#добавляем репозиторий, и обновляем дистрибутив Ubuntu 18.04
echo "deb http://us.archive.ubuntu.com/ubuntu/ bionic main restricted" >/etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted" >>/etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ bionic universe" >>/etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ bionic multiverse" >>/etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates multiverse" >>/etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse" >>/etc/apt/sources.list
echo "deb http://security.ubuntu.com/ubuntu bionic-security main restricted" >>/etc/apt/sources.list
echo "deb http://security.ubuntu.com/ubuntu bionic-security universe" >>/etc/apt/sources.list
echo "deb http://security.ubuntu.com/ubuntu bionic-security multiverse" >>/etc/apt/sources.list
apt-get update
apt-get upgrade -y

#установка ПО
apt-get install mc screen git zip htop lftp iperf axel wput wget curl gcc build-essential cmake xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp tuxcmd gimp wine-stable firefox libreoffice -y

# ПО для шифрования. мануал https://linuxmasterclub.ru/veracrypt-howto-encrypt-files/
add-apt-repository ppa:unit193/encryption -y
apt-get update
apt install veracrypt -y

# Устанавливаем кол-во сессий разрешенных для подключения
sed -i 's|MaxSessions=50|MaxSessions=1|' /etc/xrdp/xrdp.ini

# меняем RDP порт на 3390, отключаем логи
sed -i 's|port=3389|port=3390|' /etc/xrdp/xrdp.ini
sed -i 's|EnableSyslog=true|EnableSyslog=false|' /etc/xrdp/xrdp.ini
sed -i 's|#ls_title=My Login Title|s_title=serv|' /etc/xrdp/xrdp.ini
sed -i 's|ls_top_window_bg_color=009cb5|ls_top_window_bg_color=000000|' /etc/xrdp/xrdp.ini

#добавим язык 
cat > /etc/default/keyboard << HERE
XKBMODEL="pc105"
XKBLAYOUT="us,ru"
XKBVARIANT=","
XKBOPTIONS="grp:alt_shift_toggle,grp_led:scroll"
BACKSPACE="guess"
HERE

#не забывая что переключение происходит сочетанием  клавиш alt+shift
cat >> /etc/xrdp/xrdp_keyboard.ini << HERE
[rdp_keyboard_ru]
keyboard_type=4
keyboard_type=7
keyboard_subtype=1
model=pc105
options=grp:alt_shift_toggle
rdp_layouts=default_rdp_layouts
layouts_map=layouts_map_ru
[layouts_map_ru]
rdp_layout_us=us,ru
rdp_layout_ru=us,ru 
HERE

adduser xrdp ssl-cert
service xrdp restart
service xrdp-sesman restart

#удаляем IPV6
#echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
#echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
#sysctl -p
# добавляем swap 4 gb
dd if=/dev/zero of=/swapfile bs=512MB count=8
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile   none    swap    sw    0   0" | tee /etc/fstab -a

#TOR - Весь трафик  перенаправляется на Tor
apt install tor -y
echo 'TransPort 9040' >> /etc/tor/torrc
systemctl restart tor
systemctl enable tor 
iptables -t nat -A OUTPUT ! -s 127.0.0.1/8 -p tcp --syn -j REDIRECT --to-ports 9040
cat > /etc/rc.local << HERE
#!/bin/sh -e 
iptables -t nat -A OUTPUT ! -s 127.0.0.1/8 -p tcp --syn -j REDIRECT --to-ports 9040
exit 0 
HERE
chmod +x /etc/rc.local 
systemctl enable rc.local

#ssh Вставить свой публичный ключ, Строка должна начинаться с ssh-rsa AAA..
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAoHfm4pvvJw0NUUv3nKez4MlX4v/gV+8TWvqMwVbbixRdXI4hXtZtX0HMN3jU1ObV+KTFJW0nwqG2Al52BSUWyDr7MNQ9N+z6FV81uEtTTvEICL2PtyTE6bKLTJrJ5xt+irEksKjfPlHqNAHXGKht7lVYu/GdaJo1JhTuujkfTG+Le5rJ2m21wNak/pJDag5bsRip30ZB/grhIQB9tQ02MmnX2HnsnHUBtHMGIZHQK5s9WaO79ioea4ZtjsCiZTaET75NOeAVJzLjnnaGbdoDJ9qQ3+39k9jE7w1ZXGoXYIDD/SsTZhpUDfrH0sgI6A9D+PbRl3epZXR4wab1el5kPw==' > /root/.ssh/authorized_keys

#Отключаем вход по паролю
#sed -i 's|#PasswordAuthentication yes|PasswordAuthentication no|' /etc/ssh/sshd_config
#echo 'AddressFamily inet' >> /etc/ssh/sshd_config
#systemctl restart sshd

#настройка фаервола. Запрещаем все входящие кроме RDP и SSH
echo “1” > /proc/sys/net/ipv4/icmp_echo_ignore_all
echo “net.ipv4.icmp_echo_ignore_all = 1” >> /etc/sysctl.conf
sysctl -p

ufw allow 22
ufw allow 3390
ufw enable

#logs delete
### Crontab ###
crontab -l | { cat; echo "*/5 * * * *  for CLEAN in \$(find /var/log/* -type f); do cat /dev/null > \$CLEAN ; done "; } | crontab -

