#!/bin/bash

rpm -q libvirt || {
    yum install -y libvirt-devel libvirt libvirt-daemon-kvm
}

systemctl enable libvirtd
systemctl status libvird || {
    systemctl start libvirtd
}
