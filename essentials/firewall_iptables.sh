echo "
______ ___________ _____ _    _  ___  _     _ 
|  ___|_   _| ___ |  ___| |  | |/ _ \| |   | |
| |_    | | | |_/ | |__ | |  | / /_\ | |   | |
|  _|   | | |    /|  __|| |/\| |  _  | |   | |
| |    _| |_| |\ \| |___\  /\  | | | | |___| |____
\_|    \___/\_| \_\____/ \/  \/\_| |_\_____\_____/"

# CLEAR RULES

sudo iptables -t filter -F
sudo iptables -t filter -X


#loop-back (localhost)
sudo iptables -t filter -A INPUT -i lo -j ACCEPT
sudo iptables -t filter -A OUTPUT -o lo -j ACCEPT

#SSH ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 22 -j ACCEPT
  
# Active Localhost OPENVPN SECURITY
sudo iptables -t filter -A INPUT -p tcp --dport 22 -s 100:100:100:100 -j ACCEPT
  
#HTTPS
sudo iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 443 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p udp --dport 443 -j ACCEPT


# ANTI DDOS

sudo iptables -A FORWARD -p tcp --syn -m limit --limit 1/second -j ACCEPT
sudo iptables -A FORWARD -p udp -m limit --limit 1/second -j ACCEPT
sudo iptables -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT
sudo iptables -A FORWARD -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT


# Reject spoofed packets

sudo iptables -A INPUT -s 10.0.0.0/8 -j DROP
sudo iptables -A INPUT -s 169.254.0.0/16 -j DROP
sudo iptables -A INPUT -s 172.16.0.0/12 -j DROP
sudo iptables -A INPUT -s 127.0.0.0/8 -j DROP
sudo iptables -A INPUT -s 224.0.0.0/4 -j DROP
sudo iptables -A INPUT -d 224.0.0.0/4 -j DROP
sudo iptables -A INPUT -s 240.0.0.0/5 -j DROP
sudo iptables -A INPUT -d 240.0.0.0/5 -j DROP
sudo iptables -A INPUT -s 0.0.0.0/8 -j DROP
sudo iptables -A INPUT -d 0.0.0.0/8 -j DROP
sudo iptables -A INPUT -d 239.255.255.0/24 -j DROP
sudo iptables -A INPUT -d 255.255.255.255 -j DROP

# Drop all invalid packets
sudo iptables -A INPUT -m state --state INVALID -j DROP
sudo iptables -A FORWARD -m state --state INVALID -j DROP
sudo iptables -A OUTPUT -m state --state INVALID -j DROP

# Drop excessive RST packets to avoid smurf attacks
sudo iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT

# Anyone who tried to portscan us is locked out for an entire day.

sudo iptables -A INPUT   -m recent --name portscan --rcheck --seconds 86400 -j DROP
sudo iptables -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP

# Once the day has passed, remove them from the portscan list

sudo iptables -A INPUT   -m recent --name portscan --remove
sudo iptables -A FORWARD -m recent --name portscan --remove

# These rules add scanners to the portscan list, and log the attempt.

sudo iptables -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"
sudo iptables -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP
sudo iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"
sudo iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP

# Drop all invalid packets

sudo iptables -A INPUT -m state --state INVALID -j DROP
sudo iptables -A FORWARD -m state --state INVALID -j DROP
sudo iptables -A OUTPUT -m state --state INVALID -j DROP

# Conf 2

sudo iptables -A INPUT -p tcp --syn -m limit --limit 2/s --limit-burst 30 -j ACCEPT
sudo iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -m limit --limit 1/h -j ACCEPT
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -m limit --limit 1/h -j ACCEPT

# MYSQL

sudo iptables -t filter -A INPUT -p tcp --dport 3306 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 3306 -j ACCEPT

# Account

sudo iptables -t filter -A OUTPUT -p udp --dport 587 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 587 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p udp --dport 587 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 587 -j ACCEPT


# ANTI DDOS Production Server WEB

sudo iptables -N http-flood
sudo iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 1 -j http-flood
sudo iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 1 -j http-flood
sudo iptables -A http-flood -m limit --limit 10/s --limit-burst 10 -j RETURN
sudo iptables -A http-flood -m limit --limit 1/s --limit-burst 10 -j LOG --log-prefix "HTTP-FLOOD "
sudo iptables -A http-flood -j DROP
sudo iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 20 -j DROP
sudo iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 20 -j DROP
sudo iptables -A INPUT -p tcp --dport 80 -i eth0 -m state --state NEW -m recent --set
sudo iptables -I INPUT -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 10 --hitcount 20 -j DROP
sudo iptables -A INPUT -p tcp --dport 443 -i eth0 -m state --state NEW -m recent --set
sudo iptables -I INPUT -p tcp --dport 443 -m state --state NEW -m recent --update --seconds 10 --hitcount 20 -j DROP
sudo iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 13 -j DROP
sudo iptables -N flood
sudo iptables -A flood -j LOG --log-prefix "FLOOD "
sudo iptables -A flood -j DROP
sudo iptables -t filter -N syn-flood
sudo iptables -t filter -A INPUT -i eth0 -p tcp --syn -j syn-flood
sudo iptables -t filter -A syn-flood -m limit --limit 1/sec --limit-burst 4 -j RETURN
sudo iptables -t filter -A syn-flood -j LOG --log-prefix "IPTABLES SYN-FLOOD:"
sudo iptables -t filter -A syn-flood -j DROP
sudo iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
sudo iptables -t mangle -A PREROUTING -p icmp -j DROP
sudo iptables -A INPUT -p tcp -m connlimit --connlimit-above 80 -j REJECT --reject-with tcp-reset
sudo iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
sudo iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP
sudo iptables -t mangle -A PREROUTING -f -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
sudo iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP
sudo iptables -N port-scanning
sudo iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
sudo iptables -A port-scanning -j DROP
 
echo "Instação Completa
Leandrocore~~

"
