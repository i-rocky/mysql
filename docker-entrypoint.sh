#!/usr/bin/env bash

if [ -z "$(ls -A /var/lib/mysql)" ]; then
mysqld --initialize --basedir=/usr/local/mysql --datadir=/var/lib/mysql \
    && mysql_ssl_rsa_setup
fi
