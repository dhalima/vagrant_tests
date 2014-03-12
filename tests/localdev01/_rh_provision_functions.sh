#!/bin/bash

function _y_install() {
    for _package_name_and_version; do true; done

    # http://www.linuxjournal.com/article/8919
    _package_name=`echo ${_package_name_and_version%*-*-*}` # removes majorVersion-minorVersion from the right

    echo "package name ${_package_name}"

    if ! yum list installed | grep -i "^${_package_name}"; then
	yum --enablerepo=ius-archive -y install $*

	return 0
    else
	return -1
    fi
}

function _rpm() {
    for _package_name; do true; done

    _package_name=`basename ${_package_name}`
    _package_name=`echo ${_package_name} | cut -f1 -d'.'`
    
    if ! rpm -qa | grep -i "^${_package_name}"; then
	rpm -Uvh $*
    fi
}


function prepare() {    
    _rpm http://dl.iuscommunity.org/pub/ius/stable/CentOS/5/x86_64/epel-release-5-4.noarch.rpm
    _rpm http://dl.iuscommunity.org/pub/ius/stable/CentOS/5/x86_64/ius-release-1.0-11.ius.centos5.noarch.rpm

    _y_install yum-fastestmirror
}


function install_apache() {
#    yum install apache-2.2.3
    if _y_install httpd-2.2.3-82.el5.centos; then
	/sbin/chkconfig httpd on
    fi
}

function install_mysql() {
#    yum install mysql-5.5.16
    if _y_install mysql55-5.5.30-1.ius.centos5; then
	/sbin/chkconfig mysqld on
    fi
}

function install_phpadmin() {
# http://vpsshell.co.uk/index.php/centosrhel-lamp-apache-php-and-mysql-in-linux/
	_y_install phpmyadmin
    }

function install_php() {
# http://thepoch.com/2013/installing-php-5.2-on-centos-5-using-the-ius-community-project-repository.html
#    yum install php-5.2.14
    _y_install php52-5.2.17-6.ius.centos5
}

function install_apc() {
    if ! yum list installed | grep -i 'php-pear'; then
	_php_version=`yum list installed | grep php | awk '{print $2}' | head -1`
	_httpd_version=`yum list installed | grep httpd | awk '{print $2}' | head -1`
	
	_y_install php52-devel-${_php_version}
	_y_install httpd-devel-${_httpd_version}
	_y_install php-pear
	_y_install pcre-devel
	_y_install gcc
	_y_install make
    fi

    if ! pecl list | grep -i apc; then		
	pecl install apc-3.1.9
	
	echo "extension=apc.so" > /etc/php.d/apc.ini
	
	service httpd restart
    fi
}