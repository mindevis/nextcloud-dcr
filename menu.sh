#!/bin/bash

function do_main_menu ()
{
    SELECTION=$(whiptail --title "Меню скрипта" --menu "" 15 70 8 \
    "1" "Установить Nextcloud Docker" \
    "2" "Установить PHPMyAdmin" 3>&1 1>&2 2>&3)

    if [ "$SELECTION" == '1' ]; then
        do_install_nextcloud
    fi
}
function do_install_nextcloud ()
{
    SELECTION1=$(whiptail --title "Меню скрипта" --menu "" 15 70 8 \
    "1 " "Nextcloud: MariaDB + Apache2 (Only HTTP)" \
    "2 " "Nextcloud: Nginx + MariaDB + Apache2 + Let's Encrypt (Only HTTPS)" 3>&1 1>&2 2>&3)

    if [ "$SELECTION1" == '1' ]; then
        do_install_nextcloud_ma
    fi
}
function do_install_nextcloud_ma ()
{
    yum update -y
}
do_main_menu