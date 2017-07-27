#!/bin/bash

rpm -qa|grep pypy || {
    yum install -y pypy pypy-devel
    pypy -m ensurepip
}

# Backup pip 
readlink /usr/bin/pip || {
    [ -f /usr/bin/python-pip ] || mv /usr/bin/pip /usr/bin/python-pip
}

ln -sf /usr/lib64/pypy-5.0.1/bin/pip /usr/bin/pip
ln -sf /usr/lib64/pypy-5.0.1/bin/pypy /usr/bin/python
