#!/bin/bash

set -x

cd /home/vpn/easyrsa
./easyrsa gen-req server nopass <<< 'yes \n \n' #&>/dev/null
scp -o StrictHostKeyChecking=no /home/vpn/easyrsa/pki/reqs/server.req $1:~/requests/server
sleep 5
scp $1:~/server.crt ~/.
scp $1:~/ca.crt ~/.
ssh $1 rm ~/server.crt ~/ca.crt
sudo mv ~/*.crt ~/easyrsa/pki/private/server.key /etc/openvpn/server


exit 0
