#!/usr/bin/env bash

if [[ -z $1 ]]
then
    echo "Need a node number e.g. 2 for db2"
    echo "$0 2"
    exit 1
fi

N="db${1}"
P=$((3307 + ${1}))

docker run -d \
    --name ${N} \
    --hostname ${N} \
    -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 \
    -v ${PWD}/cnf:/etc/mysql/conf.d \
    -p ${P}:3306 \
    --net=galera-network \
    mariadb:10.11 \
    --wsrep-node-name=${N} \
    --wsrep-node-address=${N} \
    --wsrep-cluster-address="gcomm://db1"