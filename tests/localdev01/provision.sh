#!/bin/bash

echo $0

. /vagrant/_rh_provision_functions.sh

install_mysql
install_apache
install_php
#install_apc