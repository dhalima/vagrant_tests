#!/bin/bash

function _y_install() {
    for _package_name_and_version; do true; done

    # http://www.linuxjournal.com/article/8919
    _package_name=`echo ${_package_name_and_version%*-*-*}` # removes majorVersion-minorVersion from the right

    #echo "package name ${_package_name}"

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
    _y_install unzip
    _y_install telnet
}

function install_openssl() {
    _y_install openssl
}

function install_apache() {
# apache-2.2.3 (httpd-2.2.3-82.el5.centos)
    if _y_install httpd-2.2.3-83.el5.centos; then
	/sbin/chkconfig httpd on
	service httpd start
    fi

    if _y_install mod_ssl; then
# http://wiki.centos.org/HowTos/Https
	mkdir certificates
	cd certificates

	_hostname=`hostname`

	openssl genrsa -out ss_ca.key 2048 
	openssl req -new -key ss_ca.key -out ss_ca.csr -subj "/C=CO/ST=State/L=City/O=Company/OU=Department/CN=${_hostname}"
	openssl x509 -req -days 365 -in ss_ca.csr -signkey ss_ca.key -out ss_ca.crt

	cp ss_ca.crt /etc/pki/tls/certs
	cp ss_ca.key /etc/pki/tls/private/ss_ca.key
	cp ss_ca.csr /etc/pki/tls/private/ss_ca.csr

	cd -

	sed -i.bak 's/\(^SSLCertificateFile .*\)/SSLCertificateFile \/etc\/pki\/tls\/certs\/ss_ca.crt\n#\1/g' /etc/httpd/conf.d/ssl.conf
	sed -i.bak 's/\(^SSLCertificateKeyFile .*\)/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/ss_ca.key\n#\1/g' /etc/httpd/conf.d/ssl.conf

	service httpd restart
    fi
}

function install_mysql() {
# mysql-5.5.16 (mysql55-5.5.30-1.ius.centos5)
    _y_install mysql55-5.5.36-1.ius.centos5
    if _y_install mysql55-server-5.5.36-1.ius.centos5; then
	/sbin/chkconfig mysqld on
	service mysqld start
    fi
}

function install_php_admin() {
# http://vpsshell.co.uk/index.php/centosrhel-lamp-apache-php-and-mysql-in-linux/
	_y_install phpmyadmin
    }

function install_php() {
# http://thepoch.com/2013/installing-php-5.2-on-centos-5-using-the-ius-community-project-repository.html
# php-5.2.14 (php52-5.2.17-6.ius.centos5)
    if _y_install php52-5.2.17-6.ius.centos5; then
	_y_install php52-xml
	_y_install php52-ldap
	_y_install php52-mhash
	_y_install php52-soap
    fi
}

function install_php_pear() {
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
}

function install_apc() {
    if ! pecl list | grep -i apc; then		
	pecl install apc-3.1.9
	
	echo "extension=apc.so" > /etc/php.d/apc.ini
	
	service httpd restart
    fi
}