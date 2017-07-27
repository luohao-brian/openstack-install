#!/bin/bash

source $PWD/glance_env.sh
source ../keystone/openrc_admin.sh

# Create the glance user
openstack user show glance || {
    openstack user create --domain default --password $GLANCE_PASS glance
}
# Add the admin role to the glance user and service project
openstack role add --project service --user glance admin

# Create the glance service entity
openstack service show glance || {
    openstack service create --name glance --description "OpenStack Image" image
}

# Create the Image service API endpoints
openstack endpoint list|grep image || {
    openstack endpoint create --region RegionOne image public http://controller:9292
    openstack endpoint create --region RegionOne image internal http://controller:9292
    openstack endpoint create --region RegionOne image admin http://controller:9292
}
# config
crudini --set /etc/glance/glance-api.conf DEFAULT log_date_format  "%Y-%m-%d %H:%M:%S"
crudini --set /etc/glance/glance-api.conf DEFAULT log_file  "/var/log/glance.log"
crudini --set /etc/glance/glance-api.conf DEFAULT debug  "true"
crudini --set /etc/glance/glance-api.conf database connection "mysql+pymysql://$GLANCE_DBUSER:$GLANCE_DBPASS@localhost/$GLANCE_DBNAME"
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri "http://controller:5000"
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url "http://controller:35357"
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers "controller:11211"
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type "password"
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name "default"
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name "default"
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name "service"
crudini --set /etc/glance/glance-api.conf keystone_authtoken username "glance"
crudini --set /etc/glance/glance-api.conf keystone_authtoken password "$GLANCE_PASS"
crudini --set /etc/glance/glance-api.conf paste_deploy flavor "keystone"
crudini --set /etc/glance/glance-api.conf glance_store stores "file,http"
crudini --set /etc/glance/glance-api.conf glance_store default_store "file"
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir "/var/lib/glance/images/"


crudini --set /etc/glance/glance-registry.conf DEFAULT log_date_format  "%Y-%m-%d %H:%M:%S"
crudini --set /etc/glance/glance-registry.conf DEFAULT log_file  "/var/log/glance-registry.log"
crudini --set /etc/glance/glance-registry.conf DEFAULT debug  "true"
crudini --set /etc/glance/glance-registry.conf database connection "mysql+pymysql://$GLANCE_DBUSER:$GLANCE_DBPASS@localhost/$GLANCE_DBNAME"
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri "http://controller:5000"
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url "http://controller:35357"
crudini --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers "controller:11211"
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_type "password"
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name "default"
crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name "default"
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name "service"
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username "glance"
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password "$GLANCE_PASS"
crudini --set /etc/glance/glance-registry.conf paste_deploy flavor "keystone"

pyroot=/usr
readlink /usr/bin/python | grep pypy && {
    pyroot=/usr/lib64/pypy-5.0.1
}

# Populate the Image service database
res=`mysql -h$DB_HOST -u$DB_USER -p$DB_PASS -e "select count(*) from information_schema.tables where table_schema='glance';"`
count=`echo $res|awk -F ' ' '{print $2}'`


if [ "$count" -eq 0 ];then
  su -s /bin/sh -c "$pyroot/bin/glance-manage db_sync" 
fi


