#!/bin/bash

source $PWD/centos_env.sh

# Install the package:
rpm -q rabbitmq-server || {
    yum install -y rabbitmq-server
}

# Start the message queue service and configure it to start when the system boots:
systemctl enable rabbitmq-server.service
systemctl status rabbitmq-server.service || {
    systemctl start rabbitmq-server.service
}

rabbitmqctl list_user | grep openstack || { 
    # Add the openstack user:
    rabbitmqctl add_user $RABBIT_USER $RABBIT_PASS

    #Permit configuration, write, and read access for the openstack user:
    rabbitmqctl set_permissions $RABBIT_USER ".*" ".*" ".*"
}
