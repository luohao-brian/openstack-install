#!/bin/bash

source $PWD/keystone_env.sh

# Create the service entity for the Identity service
openstack service show keystone || {
    openstack service create --name keystone --description "OpenStack Identity" identity
}

# OpenStack uses three API endpoint variants for each service: admin, internal, and public. 
#
# The admin API endpoint allows modifying users and tenants by default, while the public 
# and internal APIs do not allow these operations. 
#
# In a production environment, the variants might reside on separate networks that service 
# different types of users for security reasons. 
openstack endpoint list|grep keystone || {
    openstack endpoint create --region RegionOne identity public http://controller:5000/v3
    openstack endpoint create --region RegionOne identity internal http://controller:5000/v3
    openstack endpoint create --region RegionOne identity admin http://controller:35357/v3
}

# Create the default domain
openstack domain show default || {
    openstack domain create --description "Default Domain" default
}

# Create an administrative project, user, and role for administrative operations
openstack project show admin || {
    openstack project create --domain default --description "Admin Project" admin
}

openstack user show admin || {
    openstack user create --domain default --password $ADMIN_PASS admin
}

openstack role show admin || {
    openstack role create admin
}
openstack role add --project admin --user admin admin

# Create the service project
openstack project show service || {
    openstack project create --domain default --description "Service Project" service
}

# Regular (non-admin) tasks should use an unprivileged project and user. 
# As an example, Create the demo project:
openstack project show demo || {
    openstack project create --domain default --description "Demo Project" demo
}
# Create the demo user
openstack user show demo || {
    openstack user create --domain default --password $DEMO_PASS demo
}
# Create the user role
openstack role show user || {
    openstack role create user
}
# Add the user role to the demo project and user
openstack role add --project demo --user demo user
