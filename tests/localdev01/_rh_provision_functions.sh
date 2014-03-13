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

    _y_install mod_ssl
}


function install_mysql55() {
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

function install_php52() {
# http://thepoch.com/2013/installing-php-5.2-on-centos-5-using-the-ius-community-project-repository.html
# php-5.2.14 (php52-5.2.17-6.ius.centos5)
    if _y_install php52-5.2.17-6.ius.centos5; then
	_y_install php52-xml
	_y_install php52-ldap
	_y_install php52-mhash
	_y_install php52-soap
    fi
}

function install_php52_pear() {
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

function dev_change_udev() {
    _y_install screen

    if [ ! -f /etc/udev/rules.d/50-vagrant-mount.rules ]; then
	_start_cmd="sleep 5"
	_stop_cmd="sleep 5"

	for _service in httpd mysql; do
	    if ! yum list installed | grep -i "^${_service}"; then
		_start_cmd="${_start_cmd}; /sbin/service/${_service} start"
		_stop_cmd="${_stop_cmd}; /sbin/service/${_service} stop"
	    fi
	done

	cat << EOF > /etc/udev/rules.d/50-vagrant-mount.rules
# Start on mount
SUBSYSTEM=="bdi",ACTION=="add",RUN+="/usr/bin/screen -m -d bash -c '${_start_cmd}'"
# Stop on unmount
SUBSYSTEM=="bdi",ACTION=="remove",RUN+="/usr/bin/screen -m -d bash -c '${_stop_cmd}'"
EOF
	
    fi
}

function dev_change_apache() {
    if yum list installed | grep -i '^mod_ssl'; then

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


function dev_change_smtp_server() {
    # http://wiki.centos.org/HowTos/postfix
    # http://www.linuxquestions.org/questions/red-hat-31/can%27t-change-default-mta-centos-6-a-929303/
    # http://charlesauer.net/tutorials/centos/postfix-as-gmail-relay-centos.php

    if _y_install postfix; then
	if ! yum list installed | grep -i '^sendmail'; then
	    yum erase sendmail
	fi
	
	/sbin/chkconfig postfix on
	service postfix start
    fi

    if ! grep -i --no-messages --quiet '\[smtp\.gmail\.com\]:587' /etc/postfix/sasl_passwd /etc/postfix/main.cf; then
# smtp.gmail.com doesn't appear in any config file

	mkdir /etc/postfix
	
	cat << EOF >> /etc/postfix/sasl_passwd
[smtp.gmail.com]:587     your_gmail_address:your_gmail_password
EOF
		
	cat << EOF >> /etc/postfix/main.cf
#relayhost = [smtp.gmail.com]:587
relayhost = [aspmx.l.google.com]:25
smtp_sasl_auth_enable = no
#smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = anonymous
#smtp_sasl_security_options = noanonymous
# Secure channel TLS with exact nexthop name match.
smtp_tls_security_level = secure
smtp_tls_mandatory_protocols = TLSv1
smtp_tls_mandatory_ciphers = high
smtp_tls_secure_cert_match = nexthop
smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt
mynetworks = 192.168.0.0/24 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
EOF
	
	postmap /etc/postfix/transport
	
	postmap /etc/postfix/sasl_passwd
	
	chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
	
	chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
	
	service postfix restart
    fi   
}