#!/bin/bash

yum install -y git crudini gcc openssl-devel libxml2-devel libxslt-devel python2-pip

pip --version|grep "9.0" || {
    pip install --upgrade pip
}

[ -d ~/.pip ] || {
mkdir ~/.pip
cat <<EOF > ~/.pip/pip.conf
[list]
format=columns
EOF
}
