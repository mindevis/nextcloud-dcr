#!/bin/bash

echo "Check for updates"
yum update -y

echo "Install needed software"
yum install epel-release vim pwgen htop lsof strace psmisc ncdu net-tools mc -y

echo "Download and Install Docker Engine"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker $USER
service docker start
systemctl enable docker.service

echo "Download and Install Docker-Compose"
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Adding rules to Firewall"
firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --reload
echo "Restart Firewall"
service firewalld restart

echo "Create env file for mariadb"
if [ -f ".mariadb.env" ]; then
    rm -f .mariadb.env
else
    touch .mariadb.env
fi

echo "Create env file for nextcloud"
if [ -f ".nextcloud.env" ]; then
    rm -f .nextcloud.env
else
    touch .nextcloud.env
fi

echo "MYSQL_ROOT_PASSWORD="$(pwgen 25 1) > .mariadb.env
echo "MYSQL_USER=user_"$(pwgen 5 1) >> .mariadb.env
echo "MYSQL_PASSWORD="$(pwgen 15 1) >> .mariadb.env
echo "MYSQL_DATABASE=nextcloud_prod" >> .mariadb.env

awk 'NR>=2 && NR<=4' .mariadb.env > .nextcloud.env
echo "MYSQL_HOST=nextcloud" >> .nextcloud.env
echo "NEXTCLOUD_ADMIN_USER=hoster_nextcloud" >> .nextcloud.env
echo "NEXTCLOUD_ADMIN_PASSWORD=hoster_nextcloud" >> .nextcloud.env
echo "NEXTCLOUD_DATA_DIR=/var/www/html/data" >> .nextcloud.env
echo "NEXTCLOUD_TRUSTED_DOMAINS="$(hostname -i) $(hostname -f) >> .nextcloud.env

echo "Pulling mariadb and nextcloud images"
docker pull mariadb:latest
docker pull nextcloud:latest

echo "Check containers, if exist delete containers"
if (( $(docker ps --filter name=mariadb-node | wc -l) != 1))
then
    echo "Stop mariadb-node container"
    docker stop mariadb-node
    echo "Delete mariadb-node container"
    docker rm mariadb-node
fi

if (( $(docker ps --filter name=nextcloud-node | wc -l) != 1))
then
    echo "Stop nextcloud-node container"
    docker stop nextcloud-node
    echo "Delete nextcloud-node container"
    docker rm nextcloud-node
fi

echo "Run mariadb-node"
docker run --name mariadb-node --restart always -v /etc/mysql:/etc/mysql/conf.d -v /var/lib/mysql:/var/lib/mysql --env-file .mariadb.env -d mariadb:latest

echo "Run nextcloud-node"
docker run --name nextcloud-node --restart always --link mariadb-node:nextcloud -v /var/www/html:/var/www/html --env-file .nextcloud.env -p 80:80 -d nextcloud:latest