#!/bin/bash

function install_apache() {
    yum install apache 2.2.3
}

function install_mysql() {
    yum install mysql 2.2.3
}

function install_php() {
    yum install php 5.2.14
}