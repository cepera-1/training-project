#!/bin/bash
#set -x
start=$(date +%H%M%S)

user=$(echo $USER)
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
        sed -i "s|- ssh-ed.*$|- $(cat ~/.ssh/id_ed25519.pub)|" /usr/share/vpn/metadata-monitor
else
        echo | ssh-keygen -t ed25519 -P "" &>/dev/null
        sed -i "s|- ssh-ed.*$|- $(cat ~/.ssh/id_ed25519.pub)|" /usr/share/vpn/metadata-monitor
fi

echo Установка монитора:
yc compute instance create --name monitor --hostname monitor \
--zone ru-central1-d \
--network-interface subnet-name=default-ru-central1-d,nat-ip-version=ipv4 \
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-24-04-lts \
--metadata-from-file user-data=/usr/share/vpn/metadata-monitor > /usr/share/vpn/monitor.inf

monitor=$(grep -A1 one_to /usr/share/vpn/monitor.inf | grep address | awk '{print $2}')
monitor_int=$(grep -B1 one_to /usr/share/vpn/monitor.inf | grep address | awk '{print $2}')

echo -e "   Monitor:\nmonitor_int:$monitor_int\nmonitor_ext:$monitor\n" >> /usr/share/vpn/config
#sed -i "s/\(monitor=\).*$/\1$monitor/" /usr/share/vpn/conf_make.sh

$ssh_test vpn@$monitor 'exit 0' &>/dev/null
while [ $? != 0 ]
do
        count 'Установка SSH соединения'
        $ssh_test vpn@$monitor 'exit 0' &>/dev/null
done
$ssh_test vpn@$monitor 'echo | ssh-keygen -t ed25519 -P "" &>/dev/null &&\
        cat ~/.ssh/id_ed25519.pub' >> ~/.ssh/authorized_keys
        cat ~/.ssh/authorized_keys | tail -n 1 >> /usr/share/vpn/config
echo Выполнено!

$ssh_test vpn@$monitor "cat ~/signal 2>/dev/null" > /usr/share/vpn/signal.m &&\
        cat /usr/share/vpn/signal.m | grep 'Instance done' &>/dev/null
while [ $? != 0 ]
do
        count "Установка и настройка демонов"
        $ssh_test vpn@$monitor "cat ~/signal 2>/dev/null" > /usr/share/vpn/signal.m &&\
                cat /usr/share/vpn/signal.m | grep 'Instance done' &>/dev/null
done
echo Выполнено!

rm /usr/share/vpn/signal.m /usr/share/vpn/monitor.inf
stop=$(date +%H%M%S)
time=$(expr $stop - $start)
min=$(expr $time / 60)
sec=$(expr $time % 60)

echo Установка заняла $min мин $sec сек.
echo "ssh vpn@$monitor"
exit 0

