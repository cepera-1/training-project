#!/bin/bash
#set -x

serv_ext=$(grep serv_ext /usr/share/vpn/config | cut -d: -f2)
serv_int=$(grep serv_int /usr/share/vpn/config | cut -d: -f2)
centr_ext=$(grep centr_ext /usr/share/vpn/config | cut -d: -f2)
centr_int=$(grep centr_int /usr/share/vpn/config | cut -d: -f2)
mon_ext=$(grep monitor_ext /usr/share/vpn/config | cut -d: -f2)
mon_int=$(grep monitor_int /usr/share/vpn/config | cut -d: -f2)


grep vpn@server /usr/share/vpn/config | ssh vpn@$centr_ext 'cat >> ~/.ssh/authorized_keys'
grep vpn@server /usr/share/vpn/config | ssh vpn@$mon_ext 'cat >> ~/.ssh/authorized_keys'
grep vpn@centr /usr/share/vpn/config | ssh vpn@$serv_ext 'cat >> ~/.ssh/authorized_keys'
grep vpn@centr /usr/share/vpn/config | ssh vpn@$mon_ext 'cat >> ~/.ssh/authorized_keys'
grep vpn@monitor /usr/share/vpn/config | ssh vpn@$serv_ext 'cat >> ~/.ssh/authorized_keys'
grep vpn@monitor /usr/share/vpn/config | ssh vpn@$centr_ext 'cat >> ~/.ssh/authorized_keys'
ssh vpn@$centr_ext "ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $serv_int 'exit 0'"
ssh vpn@$centr_ext "ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $mon_int 'exit 0'"
ssh vpn@$serv_ext "ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $centr_int 'exit 0'"
ssh vpn@$serv_ext "ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $mon_int 'exit 0'"
ssh vpn@$mon_ext "ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $centr_int 'exit 0'"
ssh vpn@$mon_ext "ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $serv_int 'exit 0'"
ssh -t vpn@$serv_ext "./server-set/make_req.sh $centr_int
       	              ./server-set/conf_make.sh
       	              sudo ./server-set/iptables.sh eth0 udp 1194"
scp vpn@$serv_ext:/etc/openvpn/client/client.conf /usr/share/vpn
ssh -t vpn@$serv_ext "sudo cp /etc/openvpn/server/ca.crt /usr/local/share/ca-certificates
		      sudo update-ca-certificates
	              sudo systemctl enable --now openvpn-server@server.service"
ssh -t vpn@$mon_ext "sudo sed -i 's/\(- job_name: node\)/\1-monitor/' /etc/prometheus/prometheus.yml
                     sudo add_exporter.sh node-ca $centr_int:9100
                     sudo add_exporter.sh node-server $serv_int:9100
	             sudo add_exporter.sh openVPN-server $serv_int:9176
		     sudo systemctl restart prometheus"

exit 0
