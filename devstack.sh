#!/bin/bash

KEYSTONE_REPO=${KEYSTONE_REPO:-"https://github.com/luohao-brian/openstack-keystone.git"}
KEYSTONE_BRANCH=${KEYSTONE_BRANCH:-"stable/mitaka"}

GLANCE_REPO=${KEYSTONE_REPO:-"https://github.com/luohao-brian/openstack-glance.git"}
GLANCE_BRANCH=${KEYSTONE_BRANCH:-"stable/mitaka"}

NOVA_REPO=${KEYSTONE_REPO:-"https://github.com/luohao-brian/openstack-nova.git"}
NOVA_BRANCH=${KEYSTONE_BRANCH:-"stable/mitaka"}

pushd centos && {
    echo "Setup yum repositories"
    sh $PWD/repo_setup.sh

    echo "Install prerequisite packages"
    sh $PWD/pkgs_common.sh

    popd
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
