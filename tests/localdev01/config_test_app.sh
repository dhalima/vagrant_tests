#!/bin/bash

CREATE USER 'drupal'@'localhost' IDENTIFIED BY 'drupal';

CREATE DATABASE drupal;



GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost';



FLUSH PRIVILEGES;