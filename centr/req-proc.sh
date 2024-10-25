#!/bin/bash

set -x

mkdir -p /home/vpn/requests/{client,server}

dir=/home/vpn/requests
list=$(ls -a $dir/$1)

for req in $list
do
	if [[ -f $dir/$1/$req && $(file $dir/$1/$req) =~ "PEM certificate request" ]]
	then
		name=$(echo $req | sed 's/\(.*\).req/\1/')
		cd /home/vpn/easyrsa
		./easyrsa import-req $dir/$1/$req $name &>/dev/null
		./easyrsa sign-req $1 $name <<< 'yes' &>/dev/null
		cp /home/vpn/easyrsa/pki/issued/$name.crt /home/vpn/.
		cp /home/vpn/easyrsa/pki/ca.crt /home/vpn/.
		chown vpn:vpn /home/vpn/*.crt
	fi
done

rm -rf $dir/$1/* 2>/dev/null

exit 0
