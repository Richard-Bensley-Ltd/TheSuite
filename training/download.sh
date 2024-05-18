#!/usr/bin/env bash

FILE="mariadb-10.11.8-rhel-8-x86_64-rpms.tar"

if [[ ! -f $FILE ]]
then
    wget https://dlm.mariadb.com/3799852/MariaDB/mariadb-10.11.8/yum/rhel/mariadb-10.11.8-rhel-8-x86_64-rpms.tar
else
    echo "File exists: ${FILE}"
fi
