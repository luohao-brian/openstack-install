#!/bin/bash

source $PWD/env.sh
source $PWD/admin-openrc.sh

# Create the neutron user
openstack user create --domain default --password $NEUTRON_PASS  neutron

# Add the admin role to the neutron user:
openstack role add --project service --user neutron admin

# Create the neutron service entity:
openstack service create --name neutron --description "OpenStack Networking" network

# Create the Neutron service API endpoints:
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696


# config

# database
openstack-config --set /etc/neutron/neutron.conf database connection "mysql+pymysql://neutron:$NEUTRON_DBPASS@localhost/neutron"

# rabbit
openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend "rabbit"
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host "controller"
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid "openstack"
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password "$RABBIT_PASS"

# keystone
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy "keystone"
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri "http://controller:5000"
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url "http://controller:35357"
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers "controller:11211"
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type "password"
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name "default"
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name "default"
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name "service"
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username "neutron"
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password "$NEUTRON_PASS"

# In the [DEFAULT] section, enable the Modular Layer 2 (ML2) plug-in and disable additional plug-ins.
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin "ml2"
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins ""

# In the [DEFAULT] and [nova] sections, configure Networking to notify Compute of network topology changes:
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes "True"
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes "True"
openstack-config --set /etc/neutron/neutron.conf nova auth_url "http://controller:35357"
openstack-config --set /etc/neutron/neutron.conf nova auth_type "password"
openstack-config --set /etc/neutron/neutron.conf nova project_domain_name "default"
openstack-config --set /etc/neutron/neutron.conf nova user_domain_name "default"
openstack-config --set /etc/neutron/neutron.conf nova region_name "RegionOne"
openstack-config --set /etc/neutron/neutron.conf nova project_name "service"
openstack-config --set /etc/neutron/neutron.conf nova username "nova"
openstack-config --set /etc/neutron/neutron.conf nova password "$NOVA_PASS"

# misc
openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path "/var/lib/neutron/tmp"

# ml2 plugin
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers "flat,vlan"
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types ""
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers "linuxbridge"
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers "port_security"
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks "provider"
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset "True"

# Linux bridge agent
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings "provider:$PROVIDER_IFCE_NAME"
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan "False"
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group "True"
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini firewall_driver "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver"

# DHCP agent
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver "neutron.agent.linux.interface.BridgeInterfaceDriver"
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver "neutron.agent.linux.dhcp.Dnsmasq"
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata "True"

# metadata agent
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip "controller"
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret "$METADATA_SECRET"

# nova
openstack-config --set /etc/nova/nova.conf neutron url "http://controller:9696"
openstack-config --set /etc/nova/nova.conf neutron auth_url "http://controller:35357"
openstack-config --set /etc/nova/nova.conf neutron auth_type "password"
openstack-config --set /etc/nova/nova.conf neutron project_domain_name "default"
openstack-config --set /etc/nova/nova.conf neutron user_domain_name "default"
openstack-config --set /etc/nova/nova.conf neutron region_name "RegionOne"
openstack-config --set /etc/nova/nova.conf neutron project_name "service"
openstack-config --set /etc/nova/nova.conf neutron username "neutron"
openstack-config --set /etc/nova/nova.conf neutron password "$NEUTRON_PASS"
openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy "True"
openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret "$METADATA_SECRET"


# expect a symbolic link /etc/neutron/plugin.ini pointing to the ML2 plug-in 
# configuration file, /etc/neutron/plugins/ml2/ml2_conf.ini
ln -sf /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

# Populate the Compute databases:
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
          --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron


# Start the Networking services and configure them to start when the system boots.
systemctl restart openstack-nova-api.service

systemctl enable neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
                neutron-metadata-agent.service
systemctl start neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
                neutron-metadata-agent.service
