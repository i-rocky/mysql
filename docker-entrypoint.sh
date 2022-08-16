#!/usr/bin/env bash

if [ -z "$(ls -A /var/lib/mysql)" ]; then
  printf "Initializing datadir\n\n"
  mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=/var/lib/mysql
  mysql_ssl_rsa_setup
  printf "Starting temporary mysql server\n\n"
  mysqld --daemonize --log-error
  if [ -n "${MYSQL_ROOT_PASSWORD}" ]
  then
    printf "Updating root user password...\n\n"
    mysql -u root -e "USE mysql; UPDATE user SET Host=\"%\" WHERE User=\"root\";FLUSH PRIVILEGES;"
    mysql -u root -e "ALTER USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  fi
  printf "Stopping temporary mysql server\n\n"
  mysqladmin --user=root --password="${MYSQL_ROOT_PASSWORD}" shutdown
  printf "Setup complete!\n\n"
fi

"$@"
