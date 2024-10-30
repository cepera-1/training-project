#!/bin/bash

start=$(date +%H%M%S)
user=$(users)
sudo chown -R $user:$user /usr/share/vpn

count() {
	for i in \| \/ \- \\ \| \/ \- \\
	do
		echo -n -e "\r$i $1 $i "
		sleep 0.5
	done
}

ssh_test="ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5"


if [[ -f ~/.ssh/id_ed25519.pub && $(file ~/.ssh/id_ed25519.pub) =~ "OpenSSH ED25519 public key" ]]
then
	sed -i "s|- ssh-ed.*$|- $(cat ~/.ssh/id_ed25519.pub)|" /usr/share/vpn/metadata-ca
else
	echo | ssh-keygen -t ed25519 -P "" &>/dev/null
	sed -i "s|- ssh-ed.*$|- $(cat ~/.ssh/id_ed25519.pub)|" /usr/share/vpn/metadata-ca
fi

echo Установка центра сертификации:
yc compute instance create --name centr --hostname centr \
--zone ru-central1-d \
--network-interface subnet-name=default-ru-central1-d,nat-ip-version=ipv4 \
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-24-04-lts \
--metadata-from-file user-data=/usr/share/vpn/metadata-ca > /usr/share/vpn/centr.inf

centr=$(grep -A1 one_to /usr/share/vpn/centr.inf | grep address | awk '{print $2}')
centr_int=$(grep -B1 one_to /usr/share/vpn/centr.inf | grep address | awk '{print $2}')

echo -e "\n   Centr:\ncentr_int:$centr_int\ncentr_ext:$centr" >> /usr/share/vpn/config

$ssh_test vpn@$centr 'exit 0' &>/dev/null
while [ $? != 0 ]
do
                 count 'Установка SSH соединения'
                 $ssh_test vpn@$centr 'exit 0' &>/dev/null
done
$ssh_test vpn@$centr 'echo | ssh-keygen -t ed25519 -P "" &>/dev/null &&\
       	cat ~/.ssh/id_ed25519.pub' >> ~/.ssh/authorized_keys  
        cat .ssh/authorized_keys | tail -n 1 >> /usr/share/vpn/config
echo Выполнено!

$ssh_test vpn@$centr "cat ~/signal 2>/dev/null" > /usr/share/vpn/signal.c &&\
       	cat /usr/share/vpn/signal.c | grep 'Instance done' &>/dev/null
while [ $? != 0 ]
do
        count "Установка и настройка демонов"
        $ssh_test vpn@$centr "cat ~/signal 2>/dev/null" > /usr/share/vpn/signal.c &&\
        cat /usr/share/vpn/signal.c | grep 'Instance done' &>/dev/null
done
echo Выполнено!

scp /usr/share/vpn/req-proc.sh vpn@$centr:~/. &>/dev/null
ssh -t vpn@$centr "sudo mv ~/req-proc.sh /usr/local/bin && sudo systemctl daemon-reload &&\
        sudo systemctl enable --now req_server.path req_client.path prometheus-node-exporter\
        && sudo chmod +x /usr/local/bin/req-proc.sh &&\
        sudo chown -R vpn:vpn ~ && req-proc.sh client" &>/dev/null
echo Демоны запущены!
rm /usr/share/vpn/centr.inf /usr/share/vpn/signal.c
stop=$(date +%H%M%S)
time=$(expr $stop - $start)
min=$(expr $time / 60)
sec=$(expr $time % 60)

echo Установка центра заняла $min мин $sec сек.
echo "ssh vpn@$centr"
exit 0
