#!/bin/bash

function isinstalled {
  if yum list installed "whiptail" >/dev/null 2>&1; then
    true
  else
    false
  fi
}

OPTION=$(whiptail --title "Меню скрипта" --menu "Опция" 15 60 4 \
"1" "Установить Nextcloud Docker"  3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $OPTION
else
    echo "You chose Cancel."
fi