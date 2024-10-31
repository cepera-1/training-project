#!/bin/bash
set -x

serv_ext=$(grep serv_ext /usr/share/vpn/config | cut -d: -f2)
serv_int=$(grep serv_int /usr/share/vpn/config | cut -d: -f2)
centr_ext=$(grep centr_ext /usr/share/vpn/config | cut -d: -f2)
centr_int=$(grep centr_int /usr/share/vpn/config | cut -d: -f2)

grep vpn@server /usr/share/vpn/config | ssh vpn@$centr_ext 'cat >> ~/.ssh/authorized_keys'
ssh vpn@$centr_ext "ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $serv_int 'exit 0'"
grep vpn@centr /usr/share/vpn/config | ssh vpn@$serv_ext 'cat >> ~/.ssh/authorized_keys'
ssh vpn@$serv_ext "ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $centr_int 'exit 0'"
ssh -t vpn@$serv_ext "./server-set/make_req.sh $centr_int &&\
       	./server-set/conf_make.sh && sudo ./server-set/iptables.sh eth0 udp 1194"
scp vpn@$serv_ext:~/client.conf /usr/share/vpn
ssh -t vpn@$serv_ext 'sudo mv ~/client.conf /etc/openvpn/client &&\
	sudo systemctl enable --now openvpn-server@server.service'

exit 0