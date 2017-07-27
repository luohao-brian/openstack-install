#!/bin/bash

yum install -y crudini python-openstackclient net-tools

echo "Turn off selinux"
cat > /etc/selinux/config <<EOF
SELINUX=disabled
SELINUXTYPE=targeted
EOF
