#!/usr/bin/env bash

docker stop db1
docker rm db1
docker run --rm -d \
   --name db1 \
    -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 \
    -v ${PWD}/setup:/docker-entrypoint-initdb.d/ \
    -v ${PWD}/cnf:/etc/mysql/conf.d \
    -p 3307:3306 \
    --net galera-network \
    mariadb:10.11 \
    --wsrep-new-cluster \
    --wsrep-node-name="db1" \
    --wsrep-node-address="db1" \
    --wsrep-cluster-address="gcomm://"
