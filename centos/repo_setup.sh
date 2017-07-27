#!/bin/bash

[ -f /etc/redhat-release ] || {
    echo "Linux distro not supported!"
    exit 1
} 

cat /etc/redhat-release | grep "CentOS Linux release 7" || {
    echo "Linux distro version not supported!"
    exit 1
}

[ -d /etc/yum.repos.d ] && {
    mv /etc/yum.repos.d /etc/yum.repos.d.old
}

echo "Setup packages repo"
cp -rf yum.repos.d /etc && yum update -y

