#!/bin/bash

function _configure_apache() {
    _conf_path=$1
    _conf_name=`basename ${_conf_path}`

    echo ln -n -s ${_conf_path} /etc/httpd/conf.d/${_conf_name}
}

function configure_mysql() {
    _dump_path=$1    
    _user=`basename $1`

    # http://www.linuxjournal.com/article/8919
    _user=`echo ${_user%*.sql}` # removes .sql from the right

mysql -u root << END
CREATE USER '${_user}'@'localhost' IDENTIFIED BY '${_user}';
CREATE DATABASE ${_user}
GRANT ALL PRIVILEGES ON ${_user}.* TO '${_user}'@'localhost';
END

cat ${_dump_path} | mysql -u ${_user} -p${_user} ${_user}
}

export -f _configure_apache

#find /vagrant/sites/conf -name '*.apache' -type f -print0 | xargs -I {} -0 bash -c '_x "$@"' _ {}
find sites/conf -name '*.apache' -type f -print0 | xargs -I {} -0 bash -c '_configure_apache "$@"' _ {}



#CREATE USER 'drupal'@'localhost' IDENTIFIED BY 'drupal';

#CREATE DATABASE drupal;



#GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost';



#FLUSH PRIVILEGES;