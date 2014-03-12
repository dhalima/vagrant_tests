#!/bin/bash

echo $0

. /vagrant/_rh_provision_functions.sh

prepare
install_mysql
install_openssl
install_apache
install_php
install_php_admin
install_php_pear
install_apc