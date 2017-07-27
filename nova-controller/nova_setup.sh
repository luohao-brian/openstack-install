#!/bin/bash

source $PWD/nova_env.sh
source ../keystone/openrc_admin.sh

# Create the nova user
openstack user show nova || {
    openstack user create --domain default --password $NOVA_PASS  nova
}

# Add the admin role to the nova user:
openstack role add --project service --user nova admin

# Create the nova service entity:
openstack service show nova || {
    openstack service create --name nova --description "OpenStack Compute" compute
}

# Create the Compute service API endpoints:
openstack endpoint list|grep compute || {
    openstack endpoint create --region RegionOne \
          compute public http://controller:8774/v2.1/%\(tenant_id\)s
    openstack endpoint create --region RegionOne \
          compute internal http://controller:8774/v2.1/%\(tenant_id\)s
    openstack endpoint create --region RegionOne \
          compute admin http://controller:8774/v2.1/%\(tenant_id\)s
}


# config
# log
crudini --set /etc/nova/nova.conf DEFAULT debug "true"
crudini --set /etc/nova/nova.conf DEFAULT log_file "/var/log/nova.log"

# rabbit
crudini --set /etc/nova/nova.conf DEFAULT rabbit_host "$RABBIT_HOST"
crudini --set /etc/nova/nova.conf DEFAULT rabbit_userid "$RABBIT_USER"
crudini --set /etc/nova/nova.conf DEFAULT rabbit_password "$RABBIT_PASS"

# scheduler
crudini --set /etc/nova/nova.conf DEFAULT compute_scheduler_driver "nova.scheduler.filter_scheduler.FilterScheduler"

# glance
crudini --set /etc/nova/nova.conf DEFAULT image_service "nova.image.glance.GlanceImageService"

# auth
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy "keystone"

# networking
crudini --set /etc/nova/nova.conf DEFAULT my_ip `getent hosts controller | awk '{ print $1 }'`
crudini --set /etc/nova/nova.conf DEFAULT network_manager "nova.network.manager.FlatDHCPManager"
crudini --set /etc/nova/nova.conf DEFAULT force_dhcp_release "True"
crudini --set /etc/nova/nova.conf DEFAULT dhcpbridge_flagfile "/etc/nova/nova.conf"
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver "nova.virt.libvirt.firewall.IptablesFirewallDriver"
crudini --set /etc/nova/nova.conf DEFAULT public_interface "eth0"
crudini --set /etc/nova/nova.conf DEFAULT vlan_interface "eth0"
crudini --set /etc/nova/nova.conf DEFAULT flat_interface "eth0"
crudini --set /etc/nova/nova.conf DEFAULT flat_network_bridge "br100"

# vnc
crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen "controller"
crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address "controller"

# libvirt
crudini --set /etc/nova/nova.conf DEFAULT compute_driver "libvirt.LibvirtDriver"
crudini --set /etc/nova/nova.conf DEFAULT instance_name_template "instance-%08x"
crudini --set /etc/nova/nova.conf DEFAULT api_paste_config "/etc/nova/api-paste.ini"

#rootwrap
crudini --set /etc/nova/nova.conf DEFAULT use_rootwrap_daemon "true"

# database
crudini --set /etc/nova/nova.conf api_database connection "mysql+pymysql://$NOVA_DBUSER:$NOVA_DBPASS@$DB_HOST/$NOVA_API_DBNAME"
crudini --set /etc/nova/nova.conf database connection "mysql+pymysql://$NOVA_DBUSER:$NOVA_DBPASS@$DB_HOST/$NOVA_DBNAME"


# keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri "http://controller:5000"
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url "http://controller:35357"
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers "controller:11211"
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type "password"
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name "default"
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name "default"
crudini --set /etc/nova/nova.conf keystone_authtoken project_name "service"
crudini --set /etc/nova/nova.conf keystone_authtoken username "nova"
crudini --set /etc/nova/nova.conf keystone_authtoken password "$NOVA_PASS"

# glance
crudini --set /etc/nova/nova.conf glance api_servers "http://controller:9292"

# libvirt
crudini --set /etc/nova/nova.conf libvirt virt_type "qemu"

# misc
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path "/var/lib/nova/tmp"

pyroot=/usr
readlink /usr/bin/python | grep pypy && {
    pyroot=/usr/lib64/pypy-5.0.1
}

# Populate the Compute databases:
res=`mysql -h$DB_HOST -u$DB_USER -p$DB_PASS -e "select count(*) from information_schema.tables where table_schema='nova_api';"`
count=`echo $res|awk -F ' ' '{print $2}'`
if [ "$count" -eq 0 ];then
    su -s /bin/sh -c "$pyroot/bin/nova-manage api_db sync" 
fi

res=`mysql -h$DB_HOST -u$DB_USER -p$DB_PASS -e "select count(*) from information_schema.tables where table_schema='nova';"`
count=`echo $res|awk -F ' ' '{print $2}'`
if [ "$count" -eq 0 ];then
    su -s /bin/sh -c "$pyroot/bin/nova-manage db sync" 
fi

