#!/bin/bash

echo "Check for updates"
yum update -y

echo "Install EPEL Repository"
yum install epel-release -y

echo "Install needed software"
yum install pwgen htop lsof strace ncdu net-tools mc -y

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

echo "MYSQL_ROOT_PASSWORD="$(pwgen 25 1) > .mariadb.env
echo "MYSQL_USER=user_"$(pwgen 5 1) >> .mariadb.env
echo "MYSQL_PASSWORD="$(pwgen 15 1) >> .mariadb.env
echo "MYSQL_DATABASE=nextcloud_prod" >> .mariadb.env

echo "Pulling mariadb and nextcloud images"
docker pull mariadb:latest
docker pull nextcloud:latest

echo "Stop and delete exist containers"
docker stop mariadb-node
docker rm mariadb-node
docker stop nextcloud-node
docker rm nextcloud-node

echo "Run mariadb-node"
docker run --name mariadb-node --restart always -v /etc/mysql:/etc/mysql/conf.d -v /var/lib/mysql:/var/lib/mysql --env-file .mariadb.env -d mariadb:latest

echo "Run nextcloud-node"
docker run --name nextcloud-node --restart always --link mariadb-node:nextcloud -v /var/www/html:/var/www/html -p 80:80 -d nextcloud:latest