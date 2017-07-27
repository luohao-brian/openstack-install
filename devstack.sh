#!/bin/bash


KEYSTONE_REPO=${KEYSTONE_REPO:-"https://github.com/luohao-brian/openstack-keystone.git"}
KEYSTONE_BRANCH=${KEYSTONE_BRANCH:-"stable/mitaka"}

GLANCE_REPO=${KEYSTONE_REPO:-"https://github.com/luohao-brian/openstack-glance.git"}
GLANCE_BRANCH=${KEYSTONE_BRANCH:-"stable/mitaka"}

NOVA_REPO=${KEYSTONE_REPO:-"https://github.com/luohao-brian/openstack-nova.git"}
NOVA_BRANCH=${KEYSTONE_BRANCH:-"stable/mitaka"}

pushd centos && {
    source $PWD/centos_env.sh
    
    echo "Setup yum repositories"
    sh $PWD/repo_setup.sh

    echo "Install prerequisite packages"
    sh $PWD/pkgs_common.sh

    echo "Install and setup rabbitmq service"
    sh $PWD/mq_setup.sh

    echo "Install and setup mariadb service"
    sh $PWD/mysql_setup.sh

    echo "Install and setup memcached service"
    sh $PWD/memcached_setup.sh

    echo "Setup libvirt service"
    sh $PWD/libvirt_setup.sh

    echo "Setup python tox"
    sh $PWD/tox_setup.sh

    popd
}

[ -d $PWD/gitdownload ] || {
    mkdir $PWD/gitdownload
}

pushd $PWD/gitdownload && {
    echo "Clone keyston git repo"
    git clone $KEYSTONE_REPO -b $KEYSTONE_BRANCH && {
        pushd keystone && {
            echo "Install python requirements for keystone"
            pip install -r requirements.txt

            echo "Install keystone bits"
            python setup.py install

            echo "Generate keystone config files"
            [ -d /etc/keystone ] || {
                mkdir /etc/keystone
                mkdir /etc/keystone/fernet-keys
                cp -rf etc/* /etc/keystone 
                cp /etc/keystone/keystone.conf.sample /etc/keystone/keystone.conf
            }
            popd #keystone
        }
    }
    popd #$PWD/gitdownload
}

pushd keystone && {
    echo "Setup database for keystone"
    sh keystone_db.sh

    echo "Configure keystone.ini"
    sh keystone_install.sh

    source $PWD/openrc_os.sh
    echo "Initialize keystone metadata"

    popd
}
