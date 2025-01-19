#!/bin/bash

set -x
job() {
echo -e "\n  - job_name: "$2"
    scheme: https
    tls_config:
      ca_file: $2.crt
    static_configs:
      - targets: ["$1:9100"]" >> ~/certs_temp/prometheus.yml
}
nodes_list=$(grep ext /usr/share/vpn/config | awk -F'_ext:' '{print $2,$1}')
readarray -t nodes <<< "$nodes_list"
for node in "${nodes[@]}"
do
        ip=$(echo $node | cut -d' ' -f1)
	name=$(echo $node | cut -d' ' -f2)
	ssh -t vpn@$ip "cd /etc/node_exporter
	sudo openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout $name.key -out $name.crt \
	-subj '/C=??/ST=??/L=??/O=??/CN=$name' -addext 'subjectAltName = DNS:$name, IP:$ip'
        echo 'tls_server_config:
  cert_file: $name.crt
  key_file: $name.key' > ~/web.yml && sudo mv ~/web.yml /etc/node_exporter"

        ssh -t vpn@$ip "sudo chown -R vpn:vpn /etc/node_exporter
	                  sudo systemctl enable --now prometheus-node-exporter
	                  sudo cp /etc/node_exporter/$name.crt /home/vpn/"
	mkdir -p ~/certs_temp && scp vpn@$ip:~/$name.crt ~/certs_temp
	if [ $name = 'monitor' ]
	then
		sudo sed -i "0,/^$/s//$node \n&/" /etc/hosts
	fi
done
ssh -t vpn@monitor 'sudo cp /etc/node_exporter/web.yml /etc/prometheus
                             sudo mv /etc/prometheus/prometheus.yml ~/.'
scp vpn@monitor:~/prometheus.yml ~/certs_temp
sed -i '/scrape_configs:/q' ~/certs_temp/prometheus.yml
for node in "${nodes[@]}"
do
	ssh -t vpn@monitor "sudo sed -i '0,/^$/s//$node \n&/' /etc/hosts"
	job $node
	if [[ $node =~ 'monitor' ]]
        then
                echo -e "\n  - job_name: "prometheus"
    scheme: https
    tls_config:
      ca_file: $(echo $node | cut -d' ' -f2).crt
    static_configs:
      - targets: ["$(echo $node | cut -d' ' -f2):9090"]" >> ~/certs_temp/prometheus.yml
		
        fi

done
scp -r ~/certs_temp vpn@monitor:~/. && rm -r ~/certs_temp
ssh -t vpn@monitor 'sudo mkdir -p /var/lib/prometheus
sudo cp /etc/node_exporter/monitor.{crt,key} /etc/prometheus && sudo rm ~/*.{crt,yml}
sudo mv ~/certs_temp/* /etc/prometheus/ && rm -r ~/certs_temp
sudo chown -R prometheus:prometheus /var/lib/prometheus /etc/prometheus
sudo systemctl daemon-reload && sudo systemctl enable --now prometheus'
