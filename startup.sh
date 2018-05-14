#!/bin/sh

if [ ! -d "/run/mysqld" ]; then
  mkdir -p /run/mysqld
fi

mysql_install_db --user=root > /dev/null

if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
  MYSQL_ROOT_PASSWORD=root
  echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
fi

MYSQL_DATABASE=${MYSQL_DATABASE:-""}
MYSQL_USER=${MYSQL_USER:-""}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

tfile=`mktemp`
if [ ! -f "$tfile" ]; then
    return 1
fi

cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD("$MYSQL_ROOT_PASSWORD");
CREATE USER 'root'@'0.0.0.0' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD";
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'0.0.0.0' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

if [ "$MYSQL_DATABASE" != "" ]; then
  echo "[i] Creating database: $MYSQL_DATABASE"
  echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

  if [ "$MYSQL_USER" != "" ]; then
    echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
    echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
  fi
fi

/usr/bin/mysqld --user=root --bootstrap --verbose=0 < $tfile
rm -f $tfile

exec /usr/bin/mysqld --user=root --console
