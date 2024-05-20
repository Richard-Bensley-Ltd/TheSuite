#!/usr/bin/env bash

TESTS=/usr/share/sysbench/

TABLES=16

mariadb -NBe "create schema if not exists sbtest;"
mariabd -NBe "grant all privileges on sbtest.* to 'dba'@'localhost' identified by 'dba';"

COUNT=$(mariadb -NBe "select count(table_name) from information_schema.tables where table_schema='sbtest'")
echo "Existing tables count: ${COUNT}"

if [[ $COUNT -lt $TABLES ]]
then
    mariadb -NBe "drop database if exists sbtest;"
    sysbench \
    --db-driver=mysql \
    --mysql-user=dba \
    --mysql_password=dba \
    --mysql-db=sbtest \
    --mysql-host=localhost \
    --mysql-port=3306 \
    --tables=${TABLES} \
    --table-size=10000 \
    ${TESTS}/oltp_update_non_index.lua prepare
fi

sysbench --db-driver=mysql --mysql-user=dba --mysql_password=dba --mysql-db=sbtest --mysql-host=localhost --mysql-port=3306 --tables=16 --table-size=10000 --threads=4 --time=0 --events=0 --report-interval=1 ${TESTS}/oltp_update_non_index.lua run

