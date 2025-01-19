#!/bin/bash

set -x
list=$(yc compute instance list | grep -v [AZ] | grep ' ' | awk '{print $4}')
readarray -t vms <<< "$list"
for vm in "${vms[@]}"
do
	yc compute instance delete $vm
	sudo sed -i "/$vm/d" /etc/hosts 2>/dev/null
	ssh-keygen -f /home/serg/.ssh/known_hosts -R $vm
done

sudo rm /usr/share/vpn/config
yc compute instance list

exit 0
