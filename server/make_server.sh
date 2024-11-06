#!/bin/bash
set -x
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

echo Установка сервера OpenVPN:
yc compute instance create --name server --hostname server \
--zone ru-central1-d \
--network-interface subnet-name=default-ru-central1-d,nat-ip-version=ipv4 \
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-24-04-lts \
--metadata-from-file user-data=/usr/share/vpn/metadata-server > /usr/share/vpn/server.inf

serv=$(grep -A1 one_to /usr/share/vpn/server.inf | grep address | awk '{print $2}')
serv_int=$(grep -B1 one_to /usr/share/vpn/server.inf | grep address | awk '{print $2}')

echo -e "   Server:\nserv_int:$serv_int\nserv_ext:$serv\n" >> /usr/share/vpn/config
sed -i "s/\(serv=\).*$/\1$serv/" /usr/share/vpn/conf_make.sh

$ssh_test vpn@$serv 'exit 0' &>/dev/null
while [ $? != 0 ]
do
	count 'Установка SSH соединения' 
	$ssh_test vpn@$serv 'exit 0' &>/dev/null
done
$ssh_test vpn@$serv 'echo | ssh-keygen -t ed25519 -P "" &>/dev/null &&\
        cat ~/.ssh/id_ed25519.pub' >> ~/.ssh/authorized_keys
        cat ~/.ssh/authorized_keys | tail -n 1 >> /usr/share/vpn/config
echo Выполнено!

$ssh_test vpn@$serv "cat ~/signal 2>/dev/null" > /usr/share/vpn/signal.s &&\
        cat /usr/share/vpn/signal.s | grep 'Instance done' &>/dev/null
while [ $? != 0 ]
do
        count "Установка и настройка демонов"
        $ssh_test vpn@$serv "cat ~/signal 2>/dev/null" > /usr/share/vpn/signal.s &&\
                cat /usr/share/vpn/signal.s | grep 'Instance done' &>/dev/null
done
echo Выполнено!

scp /usr/share/vpn/make_req.sh vpn@$serv:~/. &>/dev/null
scp /usr/share/vpn/conf_make.sh vpn@$serv:~/. &>/dev/null
scp /usr/share/vpn/iptables.sh vpn@$serv:~/. &>/dev/null

ssh -t vpn@$serv 'sudo chown -R vpn:vpn /home/vpn/ &&\
       mv ~/make_req.sh ~/conf_make.sh ~/iptables.sh ~/server-set/\
       && cd ~/server-set/openvpn_exporter-0.3.0 &&\
       sudo bash -c "go build -o /usr/local/bin/openvpn_exporter main.go" &>/dev/null &&\
       sudo systemctl daemon-reload &&\
       sudo systemctl enable --now openvpn_exporter.service'       
echo Демоны запущены!

rm /usr/share/vpn/server.inf /usr/share/vpn/signal.s
stop=$(date +%H%M%S)
time=$(expr $stop - $start)
min=$(expr $time / 60)
sec=$(expr $time % 60)

echo Установка заняла $min мин $sec сек.
echo "ssh vpn@$serv"
exit 0
