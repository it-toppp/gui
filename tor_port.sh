#!/bin/bash
echo 'Do you wish to enabled Full TOR? select yn in "Yes" "No"'
read -r -p "Are you sure? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
#netfilter-persistent start
# ignored location
IGN="192.168.1.0/24 192.168.0.0/24"
# Enter your tor UID
UID_TOR=$(id -u debian-tor)
# разрешаем установленные подключения
iptables -t nat -F
iptables -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
### *filter OUTPUT
iptables -t nat -A OUTPUT -m owner --uid-owner $UID_TOR -j RETURN
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353
for NET in $IGN 127.0.0.0/9 127.128.0.0/10; do
 iptables -t nat -A OUTPUT -d $NET -j RETURN
done
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
for NET in $IGN 127.0.0.0/8; do
iptables -A OUTPUT -d $NET -j ACCEPT
done
iptables -A OUTPUT -m owner --uid-owner $UID_TOR -j ACCEPT
iptables -A OUTPUT -j REJECT

echo TOR enabled &&  exit 1
fi

echo "Which protocol use?"
echo "   1) UDP"
echo "   2) TCP"
    read -p "Protocol [1]: " protocol
    until [[ -z "$protocol" || "$protocol" =~ ^[12]$ ]]; do
echo "$protocol: invalid selection."
read -p "Protocol [1]: " protocol
    done
    case "$protocol" in
1|"")
protocol=udp
;;
2)
protocol=tcp
;;
esac
   echo -n "set open port (80,443,22): "
   read PORTS
if [[ "$protocol" =~ ^(tcp)$ ]]
then
echo "TCP"
iptables -t nat -D OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040
iptables -t nat -A OUTPUT -p tcp -m tcp -m multiport ! --dports $PORTS --syn -j REDIRECT --to-ports 9040
iptables -I OUTPUT -p tcp -m tcp -m multiport --dports $PORTS -m state --state NEW -j ACCEPT
fi
if [[ "$protocol" =~ ^(udp)$ ]]
then
echo "UDP"
iptables -I OUTPUT -p udp -m udp -m multiport --dports $PORTS -m state --state NEW -j ACCEPT
fi
