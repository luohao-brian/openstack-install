#!/bin/bash

source $PWD/keystone_env.sh

crudini --set /etc/keystone/keystone.conf DEFAULT log_date_format  "%Y-%m-%d %H:%M:%S"
crudini --set /etc/keystone/keystone.conf DEFAULT log_file  "/var/log/keystone.log"
crudini --set /etc/keystone/keystone.conf DEFAULT debug "true"
crudini --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN
crudini --set /etc/keystone/keystone.conf token provider fernet
crudini --set /etc/keystone/keystone.conf database connection "mysql+pymysql://$KEYSTONE_DBNAME:$KEYSTONE_DBPASS@localhost/$KEYSTONE_DBNAME"

res=`mysql -h$DB_HOST -u$DB_USER -p$DB_PASS -e "select COUNT(*) from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA='$KEYSTONE_DBNAME' and TABLE_NAME='endpoint';"`
count=`echo $res|awk -F ' ' '{print $2}'`

pyroot=/usr
readlink /usr/bin/python | grep pypy && {
    pyroot=/usr/lib64/pypy-5.0.1
}

if [ "$count" -eq 0 ];then
  su -s /bin/sh -c "$pyroot/bin/keystone-manage db_sync"
  $pyroot/bin/keystone-manage fernet_setup --keystone-user root --keystone-group root
fi


