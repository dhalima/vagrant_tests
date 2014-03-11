#!/bin/bash

function install_apache() {
#    yum install apache-2.2.3
    yum -y install httpd-2.2.3-82.el5.centos
    /sbin/chkconfig httpd on
}

function install_mysql() {
#    yum install mysql-5.5.16
    rpm -Uvh http://mirror.webtatic.com/yum/el5/latest.rpm

    yum -y install mysql55w mysql55w-server
}

function install_php() {
    rpm -Uvh http://dl.iuscommunity.org/pub/ius/stable/CentOS/5/x86_64/ius-release-1.0-11.ius.centos5.noarch.rpm
    rpm -Uvh http://dl.iuscommunity.org/pub/ius/stable/CentOS/5/x86_64/epel-release-5-4.noarch.rpm

# http://thepoch.com/2013/installing-php-5.2-on-centos-5-using-the-ius-community-project-repository.html
#    yum install php-5.2.14
    yum -y install php52-5.2.17-6.ius.centos5
}

function install_apc() {
    _php_version=`yum list installed | grep php | awk '{print $2}' | head -1`
    _httpd_version=`yum list installed | grep httpd | awk '{print $2}' | head -1`

    yum -y --enablerepo=ius-archive install php52-devel-${_php_version}
    yum -y install httpd-devel-${_httpd_version}
    yum -y install php-pear pcre-devel gcc make

    pecl install apc-3.1.9

    echo "extension=apc.so" > /etc/php.d/apc.ini

    service httpd restart
}