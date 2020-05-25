#!/bin/bash
echo 'Do you wish to enabled Full TOR? select yn in "Yes" "No"'
read -r -p "Are you sure? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
netfilter-persistent start
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
