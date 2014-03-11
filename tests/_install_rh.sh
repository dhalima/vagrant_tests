#!/bin/bash

function install_apache() {
#    yum install apache-2.2.3
    yum install httpd-2.2.3-82.el5.centos
}

function install_mysql() {
#    yum install mysql-5.5.16
    yum install mysql55-mysql-5.5.32-3.el5
}

function install_php() {
    yum install php-5.2.14
}

function install_apc() {
    yum install php-devel-5.2.14
    yum install httpd-devel-2.2.3
    yum install php-pear pcre-devel gcc make

    pecl install apc-3.1.9

    echo "extension=apc.so" > /etc/php.d/apc.ini
}