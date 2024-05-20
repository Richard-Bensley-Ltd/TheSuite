# Galera in Docker

Setup galera in docker using existing data.

First create a network:

    docker network create --driver bridge galera-network

Create the primary server named `db1`:

    ./new-cluster.sh

Then add a server to the cluster, named `db2`:

    ./start-node.sh 2

Check the logs:

    docker logs -f db2

Wait for success messages:

    2024-04-03 14:23:56 1 [Note] WSREP: Server db2 synced with group
    2024-04-03 14:23:56 1 [Note] WSREP: Server status change joined -> synced
    2024-04-03 14:23:56 1 [Note] WSREP: Synchronized with group, ready for connections
    2024-04-03 14:23:56 1 [Note] WSREP: wsrep_notify_cmd is not defined, skipping notification.

Test the data has been synchronised:

    docker exec -it db2 mariadb -NBe "select count(*) from test.t1"
    999

Add another server named `db3`:

    ./start-node.sh 3

Once node 3 is ready, the cluster size will be 3:

    docker exec -it db1 mariadb -e "show global status like 'wsrep_cluster_size'"
    +--------------------+-------+
    | Variable_name      | Value |
    +--------------------+-------+
    | wsrep_cluster_size | 3     |
    +--------------------+-------+

Add some more data to `db1`:

    docker exec -it db1 mariadb -e "insert into test.t1 (a) values (123456)"

Then select that data from `db2` and `db3`:

    for i in {2..3}; do docker exec -it db${i} mariadb -e "select @@hostname, max(a) from test.t1"; done
    +------------+--------+
    | @@hostname | max(a) |
    +------------+--------+
    | db2        | 123456 |
    +------------+--------+
    +------------+--------+
    | @@hostname | max(a) |
    +------------+--------+
    | db3        | 123456 |
    +------------+--------+
