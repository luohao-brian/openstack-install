#!/bin/bash


# Install the packages:
yum install -y memcached python-memcached

cat /etc/sysconfig/memcached | grep "127.0.0.1" || {
    echo "OPTIONS=\"-l 127.0.0.1\"" >> /etc/sysconfig/memcached
}

# Start the Memcached service and configure it to start when the system boots:
systemctl enable memcached.service
systemctl start memcached.service
