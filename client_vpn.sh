#!/bin/bash
set -xe
if [ -z $1 ];then echo "Введите имя клиента [client123]" && exit 1;fi
centr=$(grep centr_ext /usr/share/vpn/config | cut -d: -f2)
server=$(grep serv_ext /usr/share/vpn/config | cut -d: -f2)
mkdir -p ~/client/{keys,files}
scp vpn@$server:/etc/openvpn/server/ca.crt ~/client/keys
scp vpn@$server:/etc/openvpn/server/ta.key ~/client/keys
scp vpn@$server:/etc/openvpn/client/client.conf ~/client/
cd ~/easyrsa
echo | ./easyrsa gen-req $1 nopass
scp ~/easyrsa/pki/reqs/$1.req vpn@$centr:~/. 
ssh -t vpn@$centr mv /home/vpn/$1.req /home/vpn/requests/client
mv ~/easyrsa/pki/private/$1.key ~/client/keys
sleep 5
scp vpn@$centr:/home/vpn/*.crt ~/client/keys
ssh vpn@$centr rm /home/vpn/*.crt

KEY=$(ls ~/client/keys | grep key | grep $1)
KEY_DIR=~/client/keys
OUTPUT_DIR=~/client/files
BASE_CONFIG=~/client/client.conf

cat ${BASE_CONFIG} \
<(echo -e '<ca>') \
${KEY_DIR}/ca.crt \
<(echo -e '</ca>\n<cert>') \
${KEY_DIR}/$1.crt \
<(echo -e '</cert>\n<key>') \
${KEY_DIR}/$KEY \
<(echo -e '</key>\n<tls-crypt>') \
${KEY_DIR}/ta.key \
<(echo -e '</tls-crypt>') \
> ${OUTPUT_DIR}/$1.ovpn
exit 0

