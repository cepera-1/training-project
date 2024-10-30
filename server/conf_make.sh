#!/bin/bash
#set -x

mkdir expr
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf ./expr/
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ./expr/
cd expr
echo directory created !
crt=$(ls -li /etc/openvpn/server | grep crt | grep server | awk '{print  $10}')
echo $crt

base_conf() {

sed -i 's/;\?\(dev tun\)/\1/' $1
sed -i 's/;\?\(proto  udp\)/\1/' $1
sed -i 's/;\?\(user\s\).*$/\1nobody/' $1
sed -i 's/;\?\(group\s\).*$/\1nogroup/' $1
sed -i 's/;\?\(persist\-key\)/\1/' $1
sed -i 's/;\?\(persist\-tun\)/\1/' $1
sed -i 's/\(;data-cipher.*$\)/\1\ncipher AES-256-GCM/' $1
sed -i 's/\(cipher AES-256-GCM\)/\1\nauth SHA256/' $1
sed -i 's/;\?\(verb 3\)/\1/' $1

}

base_conf server.conf
base_conf client.conf

sed -i 's/;\?\(tls\-\).*$/\1crypt ta.key/' server.conf
sed -i 's/;\?\(dh\).*$/\1 none/' server.conf 
sed -i 's/;\?\(ca\s.*$\)/\;\1/' client.conf
sed -i 's/;\?\(cert\s.*$\)/\;\1/' client.conf
sed -i 's/;\?\(key\s.*$\)/\;\1/' client.conf
sed -i "s/;\?\(cert\s\).*$/\1$crt/" server.conf
sed -i "s/;\?\(key\s\).*$/\1server.key/" server.conf
sed -i 's/\(auth SHA256\)/\1\n\nkey\-direction 1/' client.conf
sed -i "s/;\?\(remote\)\smy-server-1.*$/\1 $1 1194/" client.conf
sed -i 's/;\?\(push "redirect-gateway def1 bypass-dh\).*$/\1cp"/' server.conf
sudo sed -i 's/#\?\(net.ipv4.ip_forward=1\)/\1/' /etc/sysctl.conf
sudo sysctl -p
sudo mv client.conf ~/.
sudo mv server.conf /etc/openvpn/server/

cd ..
rm -rf expr

exit 0
