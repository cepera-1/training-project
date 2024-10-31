#!/bin/bash
set -x
centr=$(grep centr_ext /usr/share/vpn/config | cut -d: -f2)
server=$(grep serv_ext /usr/share/vpn/config | cut -d: -f2)
mkdir -p ~/client/{keys,files}
scp vpn@$server:/etc/openvpn/server/ca.crt ~/client/keys
scp vpn@$server:/etc/openvpn/server/ta.key ~/client/keys
cd ~/easyrsa
echo | ./easyrsa gen-req $1 nopass
scp ~/easyrsa/pki/reqs/$1.req vpn@$centr:~/requests/client
mv ~/easyrsa/pki/private/$1.key ~/client/keys
sleep 5
#ssh -t vpn@$centr "sudo chown -R serg:serg /home/vpn/*.crt"
scp vpn@$centr:/home/vpn/*.crt ~/client/keys
#scp $centr:~/easyrsa/pki/ca.crt ~/client/keys
ssh vpn@$centr rm /home/vpn/*.crt
cp /usr/share/vpn/client.conf ~/client/

KEY=$(ls ~/client/keys | grep key | grep client)
KEY_DIR=~/client/keys
OUTPUT_DIR=~/client/files
BASE_CONFIG=~/client/client.conf

cat ${BASE_CONFIG} \
<(echo -e '<ca>') \
${KEY_DIR}/ca.crt \
<(echo -e '</ca>\n<cert>') \
${KEY_DIR}/client*.crt \
<(echo -e '</cert>\n<key>') \
${KEY_DIR}/$KEY \
<(echo -e '</key>\n<tls-crypt>') \
${KEY_DIR}/ta.key \
<(echo -e '</tls-crypt>') \
> ${OUTPUT_DIR}/$KEY.ovpn
exit 0

