#!/bin/bash

source $PWD/env.sh

mysql -p$DB_PASS -u root -e "CREATE DATABASE neutron;"
mysql -p$DB_PASS -u root -e "GRANT ALL PRIVILEGES ON \
        neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';"
mysql -p$DB_PASS -u root -e "GRANT ALL PRIVILEGES ON \
        neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';"


