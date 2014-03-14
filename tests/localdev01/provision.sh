#!/bin/bash

echo $0

. /vagrant/_rh_provision_functions.sh

prepare
install_mysql55
install_openssl
install_apache
install_php52
install_php_admin
install_php52_pear
install_apc

# Dev enviroment tweaks
dev_change_apache
dev_change_smtp_server