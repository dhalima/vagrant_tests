#!/bin/bash

function _configure_apache() {
    _conf_path=$1
    _conf_name=`basename ${_conf_path}`

    if [ ! -e /etc/httpd/conf.d/${_conf_name} ]; then
	echo ln -n -s ${_conf_path} /etc/httpd/conf.d/${_conf_name}
    fi
}

function _configure_mysql() {
    _dump_path=$1    
    _user=`basename $1`

    # http://www.linuxjournal.com/article/8919
    _user=`echo ${_user%*.sql}` # removes .sql from the right

    if ! mysql -u root -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${_user}'" | grep -i ${_user}
#	mysql -u root << END
#CREATE USER '${_user}'@'localhost' IDENTIFIED BY '${_user}';
#CREATE DATABASE ${_user}
#GRANT ALL PRIVILEGES ON ${_user}.* TO '${_user}'@'localhost';
#END
    
	echo cat ${_dump_path} | mysql -u ${_user} -p${_user} ${_user}
    fi
}

export -f _configure_apache _configure_mysql

#find sites/conf -name '*.apache' -type f -print0 | xargs -I {} -0 bash -c '_configure_apache "$@"' _ {}
find /vagrant/apps/conf -name '*.apache' -type f -print0 | xargs -I {} -0 bash -c '_configure_apache "$@"' _ {}
find /vagrant/apps/dump -name '*.mysql' -type f -print0 | xargs -I {} -0 bash -c '_configure_mysql "$@"' _ {}


#CREATE USER 'drupal'@'localhost' IDENTIFIED BY 'drupal';

#CREATE DATABASE drupal;



#GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost';



#FLUSH PRIVILEGES;