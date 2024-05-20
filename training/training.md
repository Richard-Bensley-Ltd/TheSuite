# Training

Firstly. What are we covering? This is a 2 day course. Lots to do!

Day 1:

* Get installed and get configured.
* Get comfortable with MariaDB and data.
* Logical backups and restores. It's just Linux/Unix.
* Re-covering replication, a bit more on binary logs.
* Diff/Inc backups using a full backup and binary logs.

Day 2:

* Tips
* Slow Query Log.
* InnoDB Status and deadlock monitoring.
* InnoDB recovery steps.
* Prelude to monitoring. What is happening?
* Galera demo.

Secondly, let's get installed. Group exercise.

## Day 1

### Install

Login to both hosts
Update and Upgrade
Install MariaDB

    dnf install MariaDB-server MariaDB-client MariaDB-backup

Make sure MariaDB server is enabled and will run at startup

    systemctl enable mariadb
    systemctl restart mariadb
    systemctl status mariadb

Check the server logs

    journalctl -u mariadb

Follow the server logs

    journalctl -uf mariadb

What has been installed?

* The datadir in /var/lib/mysql
* Various mariadb-* named binaries or scripts in PATH
* The config files in /etc/mysql
* The socket file /var/run

### First configuration

What configs are where, and how they are loaded.
Notice the includes.
What do the sections mean?

We are installing dedicated database hosts.
We need to open up networking and use the available RAM.

Edit the config and set:

* `bind_address` = 0
* `innodb_buffer_pool_size` = 70% of available RAM.
* Check the error log settings, `log_error`, and set `log_warnings`

Reboot MariaDB and check are settings have taken affect:

    systemctl restart mariadb
    mariadb

Learn how to read variable values using `SHOW GLOBAL VARIABLES LIKE '%abc%'`.
Or select them directly, `SELECT @@my_var`.

### MariaDB

Now let us look around MariaDB using SQL commands.

What is the server currently doing?

    show full processlist;
    status;

Display available schemas:

    show schemas;
    show databases;
    use information_schema;
    show tables;
    show full tables;
    use mysql;
    show tables;

    use sys?;

Shortcuts to these tables?

    show global status;
    show global variables;

### Databases and Tables

Create a database:

    create database if not exists my_db;

Switch to that database:

    use my_db;

What tables are in this database?

    show tables;

Create a table:

    create table my_table (col1 int(11) not null primary key auto_increment, col2 varchar(32) not null) engine=InnoDB;

Insert some data into the table:

    insert into my_table (col2) values ("new data");

Select the new data:

    select * from my_table;

Select the data in a vertical layout:

    select * from my_table\G

Databases and tables are directories and files on disk!
By default InnoDB uses a file per-table, `innodb_file_per_table=1`.
The data is located at `datadir`:

    ls -aslh $(mariadb -NBe "select @@datadir")

Insert and read the data from another database schema:

    use test;
    insert into my_db.my_table (col2) values ("newer data");
    select * from my_db.my_table;

Update the data:

    update my_db.my_table set col2="updated data" where col1=1;
    select * from my_db.my_table;

Delete from the table:

    delete from my_db.my_table where col1=2;
    select * from my_db.my_table;

Completely erase all the data inside the table:

    truncate table my_db.my_table;

Drop the table:

    drop table my_db.my_table;

Drop the database:

    drop database my_db;

### Engines

By default we always use the InnoDB engine. An ACID compliant OLTP engine.

What other engines are available?

    show engines;
    show innodb engine status;

Wait! What makes MariaDB ACID compliant?

    `sync_binlog=1`
    `innodb_flush_log_at_trx_commit=1`
    `sql_mode=TRADITIONAL` # my oppinion

### Plugins

MariaDB has a healthy and active UDF and Plugin development community:

    show plugins;
    select * from information_schema.plugins;

### Flush!

There are various [flush](https://mariadb.com/kb/en/flush/) commands. Depending on what you are doing.

    FLUSH PRIVILGES;
    FLUSH TABLES;

### Prepare a Master or Primary for replication

We need to enable binary logging.
Assign a unique ID to the primary, and subsequent servers.
Create a database user for replication.
Enable recovery from a replica using `log_slave_updates`

First, update the primary config:

    log_bin [= name]
    server_id = 1
    log_slave_updates=1

Restart MariaDB and check the variables have been set.

    systemctl restart mariadb
    mariadb

### Creating users

We need to create a replication user

    CREATE USER 'repl'@'%' IDENTIFIED BY 'repl123';
    GRANT REPLICATION CLIENT ON *.* TO 'repl'@'%';
    FLUSH PRIVILEGES;
    SHOW GRANTS FOR 'repl'@'%';

Test the user:

    mariadb -urepl -prepl123
    SHOW GRANTS;

Create another user.

    CREATE USER 'name'@'hostmask' IDENTIFIED BY 'password';
    GRANT SELECT,INSERT ON test.* TO 'name'@'hostmask';

Test the new user:

    mariadb -uname -ppass
    SHOW GRANTS;
    SELECT * FROM mysql.user;

What you can see in `information_schema` depends on your grants.
Hence why monitoring users tend to have `SELECT` on `*.*`.

### Binary Logs

We can view the current state of the binary logs:

    show binary logs;

Time to observe the GTID.

    show global status like '%gtid%';
    show variables status like '%gtid%';

What is a GTID? What do the numbers mean?

* Domain ID, default is 0.
* Server ID, is whatever you have set it to and the source of the transaction.
* The position.

Use the `writer.sh` script to generate some data and monitor the binary log position.

We can display events in the binary log from within MariaDB:

    SHOW BINLOG EVENTS [IN 'log_name'] [FROM pos] [LIMIT [offset,] row_count]

This is quick but not very detailed.

We can use `mariadb-binlog` to view the logs.
By default `binlog_annotate_row_events` is enabled.
So the log data is accompanied by the SQL used to generate the changes.

    mariadb-binlog [options] file_name

If you want to view ROW/Binary data, it needs to be decoded:

    mariadb --base64-output=DECODE-ROWS -v file_name

What format are the logs in? 

* Statement
* Row
* Mixed (default)

How can we debug a statement that was written and replicated?
TOMORROW!

### Backup and restore

There are two main backup tools `mariadb-dump` and `mariadb-backup`.
Previously named `mysqldump` and `xtrabackup`.

Why not `mariadb-backup`? Because we have to get dirty.

Full logical backup, all databases.

    mariadb-dump --all-databases

What just happened?
Let's put it somewhere useful.

    mariadb-dump --all-databases > bkp.sql

But that is not transactoinal!

    mariadb-dump --all-databases --single-transaction

But that is too slow!

    --quick

It's too big!

    | gzip > bkp.sql.gz

Is it really compressed?

    file bkp.sql.gz

Can I use this to create a replica?

    --master-data=?

### Replication

Why replicate? Off site backups?
Read capacity? Fail-over capacity?
All of the above?

Configure the replica as above.

* `server_id`
* `log_slave_updates`
* `log_bin`

Take a backup, copy it to the replica.
Restore the backup.
Configure and start replication!

Monitor replication.
What do these fields mean?
What is a relay log?

## DAY 2

### Install a Plugin

We shall install the disks plugin which gives us table view of the local systems disks.
NOTE: this plugin ONLY works on Linux!
This plugin also requires the FILE privilege.

Install the plugin using SQL:

    INSTALL SONAME 'disks';

Or add it to the config file:

    plugin_load_add = disks

Some plugins require a different maturity level to be set in the config:

    plugin_maturity=alpha

Select from the new table:

    SELECT * FROM information_schema.DISKS;

### Replay binary logs

On server 2 stop replication.
Write more data to server 1.
Take a fresh backup from server 1:

    DATE=$(20052024_173606)
    mariadb-dump --single-transaction --quick --all-databases --master-data=1 --gtid > bkp_server1_${DATE}.sql

On server 1, flush the binary logs:

    FLUSH BINARY LOGS;

And then write more data:

    ./writer.sh 1

Create a new table:

    create table test.t2 like test.t1;
    insert into test.t2 select * from test.t1 limit 100;

Flush the binary logs again:

    FLUSH BINARY LOGS;

Now server 1 has more data than the backup.

Copy the backup and the missing binary logs to server 2.

From server 2, restore the backup

    mariadb < backup_file.sql

Make a note of the currently GTID's:

    select @@gtid_binlog_pos, @@gtid_current_pos, @@gtid_slave_pos;

Use `mariadb-binlog` to replay the files against server 2:

    mariadb-binlog [start] [stop] log_file_name[s] | mariadb

Check the GTID positions again.

Update `gtid_slave_pos` to the correct value, and start replication:

    set global gtid_slave_pos='X-Y-Z';
    start slave;

    show slave status\G

### Dicks Tips

Customise the client section of options files.

    [client-mariadb]
    show_warnings

    [mariadb-dump]
    single_transaction
    quick
    events
    triggers
    routines
    comments

Safe updates!
Append `--safe-updates` or `-U` to `mariadb`.
`DELETES` and `UPDATES` will require a key to be specified.

Transactions can be useful to undo mistakes on the fly.

    START TRANSACTION;
    DELETE FROM my_db.my_table;
    ROLLBACK;

Use Replicatoin Filters to add a non-replicated database!
Create an empty database, and let it replicate.

    CREATE DATABSE no_repl;

Update the replication filters:

    SET GLOBAL replicate_ignore_db='no_repl'; # comma seperated

Persist the change to a config file:

    [server]
    replicate_ignore_db=no_repl # one per-line

Create a rescue file using `dd`.
Running out of space will stop all operations.
Create a file around 1Gb in size.

    sudo dd if=/dev/zero of=/var/lib/mysql/rescue.file bs=1M count=1000

Use `tmux` or `screen` to handle long running processes.

Optionally give the `mysql` system user a shell.
Useful to have DBA seperate from root accounts.

    sudo groupadd -r mysql && sudo useradd -s /usr/bin/bash -r -g mysql mysql --home-dir /var/lib/mysql

Modify an existing user:

    sudo usermod mysql -s /usr/bin/bash

Common admin tasks and related information can be obtained using SQL commands.

### InnoDB status and recovery

Read through [InnoDB Recovery Modes](https://mariadb.com/kb/en/innodb-recovery-modes/).

Learn how to read the output of `SHOW ENGINE INNODB STATUS\G`.
The output is documented [here](https://mariadb.com/kb/en/show-engine-innodb-status/)

### Online DDL

MariaDB supports Online Data Definition Language.
The locking strategies available are documented [here](https://mariadb.com/kb/en/innodb-online-ddl-overview/)

### Monitoring

Create some noise:

    sudo dnf install sysbench
    ./run-sysbench.sh

We shall enable the slow query log and examine the output.
In the config enable slow query logging.
Once enabled tweak timings dynamically.

    [server]
    slow_query_log=1
    slow_query_log_file=slow.log
    long_query_time=5
    log_slow_admin_statements=1
    log_queries_not_using_indexes=0

The variable [`log_queries_not_using_indexes`](https://mariadb.com/kb/en/server-system-variables/#log_queries_not_using_indexes) is dynamic.

Restart the server

    sudo systemctl restart mariadb

Tune the `long_query_time` to start catching queries:

    set global long_query_time=0.5;

Examine the log file being created:

    sudo vim /var/lib/mysql/slow.log

Enable logging of queries not using indexes to see unoptimised tables or queries:

    set global log_queries_not_using_indexes=1;

Review the log again. When ready disable it again:

    set global log_queries_not_using_indexes=0;

### Enable the userstat plugin

The [User Statistics](https://mariadb.com/kb/en/user-statistics/) plugin creates some tables which represent in-memory hash maps which the server actively updates.
Very minimal overhead, and easier to parse than Performance Schema and Global Status.

Enable the plugin in the config file:

    [server]
    userstat=1

Or dynamically within the server:

    SET GLOBAL userstat=1;

The tables which are created:

    SELECT * FROM INFORMATION_SCHEMA.USER_STATISTICS\G
    SELECT * FROM INFORMATION_SCHEMA.CLIENT_STATISTICS\G
    SELECT * FROM INFORMATION_SCHEMA.INDEX_STATISTICS WHERE TABLE_NAME = "X";
    SELECT * FROM INFORMATION_SCHEMA.TABLE_STATISTICS WHERE TABLE_NAME='Y';

Use the show commands:

    SHOW USER_STATISTICS;
    SHOW CLIENT_STATISTICS;
    SHOW INDEX_STATISTICS;
    SHOW TABLE_STATISTICS;

The individual tables can be flushed to reset counters when monitoring changes:

    FLUSH USER_STATISTICS;
    FLUSH CLIENT_STATISTICS;
    FLUSH INDEX_STATISTICS;
    FLUSH TABLE_STATISTICS;

### Next Up

MariaDB queries to to html and iframes.
Performance Schema? In progress.
Full table scans, index misses, I/O locks/waits.

