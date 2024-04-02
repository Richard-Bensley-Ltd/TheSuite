#!/usr/bin/env bash

MARIADB_UP=$(mariadb -NBe "SELECT 1" || echo 0)
MARIADB_STATUS="{\"mariadb_up\": \"${MARIADB_UP}\"}"

if [ $? -eq 0 ]; then
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n${MARIADB_STATUS}"
else
    ERROR_STATUS="{\"status\": \"500 Internal Server Error\", \"error\": \"MariaDB is down\"}"
    echo -e "HTTP/1.1 500 Internal Server Error\r\nContent-Type: application/json\r\n\r\n${ERROR_STATUS}"


fi

