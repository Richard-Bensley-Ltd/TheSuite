# MariaDB Manual

Run, backup, restore, and monitor MariaDB Enteprise.

## MariaDB Documentation

* [Knowledge Base](https://mariadb.com/kb/en/)

## MariaDB Books

* High Performance MySQL, <https://www.amazon.co.uk/High-Performance-MySQL-Strategies-Running/dp/1492080519/>
* Mastering MariaDB, <https://www.packtpub.com/product/mastering-mariadb/9781783981540>
* MariaDB High Performance, <https://www.amazon.co.uk/MariaDB-High-Performance-Pierre-MAVRO/dp/1783981601>

## MariaDB Logs

The Error log is configured with `log_error`. By default writes to the journal when run under systemd. Either delete or don't set a value for `log_error`.

The `general_log` is dynamic, **dangerous**, and can be enabled at whim. It is a 1 for 1 copy of all SQL data and commands being executed on the server, only use for debugging. `general_log` should be set to `0` by default.

The `slow_query_log` can be enabled to capture queries and their relevant explain. Queries taking longer than `long_query_time` in seconds are logged along with their explain plans if `log_slow_verbosity` is set to `explain`.

The Audit log has more extensive parameters and runs as a plugin to MariaDB. More options [here](https://mariadb.com/kb/en/mariadb-audit-plugin-configuration/). Make sure the plugin is installed, audit logging is set to `ON`,  you have the correct output type, and you are capture the events you want.

## Plugins

Some plugins require a specific `plugin_maturity` to be set. Check the docs.

Useful plugins:

* [Audit](https://mariadb.com/kb/en/mariadb-audit-plugin/) Plugin, it audits.
* [SQL Error](https://mariadb.com/kb/en/sql-error-log-plugin/) Plugin, records mis-type and incorrect SQL into a log file.
* [Disks Plugin](https://mariadb.com/kb/en/disks-plugin/) have the system disk info available in a table.

## Data Consistency (ACID)

Once upon a time some [hero](https://jira.mariadb.org/browse/MDEV-7635) made sure MariaDB was safe, simple, and ACID compliant by default.

Atomic, Consistent, Isolated, Durable.
The data that goes in, is the data that comes out again, as well as being more durable in case of a system, disk, or network failure.

* `innodb_flush_log_at_trx=1`
* `sync_binlog=1`
* `sql_mode=STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION` (all settings are [here](https://mariadb.com/kb/en/server-system-variables/#sql_mode))

## Replication

Replication options:

* Asynchronous replication, the most prelevant option.
* Semi-Synchronous replication, enabled via a plugin, will only complete a client transaction when at least one slave has received the change.
* Galera, two phase commits, shared everything self-healing cluster. Highly recommended.
* Spider, a sharding ending. Not a ready-to-go solution.

## Failover

Choose a solution to first of all make application switchers seemless by using a proxy service, or a virtual IP.

Other solutions common for use with MariaDB include:

* Maxscale, Enterprise license required.
* ProxySQL, open source.
* HAProxy, not database aware but it is open source.

Only Maxscale can handle master promotion and something close to automatic failover. All other solutions require custom tooling.

## Scripts

### Variable overrides

Most scripts do not require any parameters and instead have variables which can be overridden in your shell.

In the following example, `MY_VAR` has a default value of `1` and can be overriden before running the script.

In the script:

    $ cat my_script.sh
    #!/bin/bash
    MY_VAR="${MY_VAR:=1}"
    echo $MY_VAR

Running the script will return to the shell:

    $ ./my_script.sh
    1

Declare the variable before hand, to override the value:

    $ export MY_VAR=2
    $ ./my_script.sh 
    2

### Per-Environment settings

Scripts which have paths to the backup mounts including `install-scripts.sh`, `full-bkp.sh`, and `sync-binlogs.sh` have different paths to where the backups are located between PROD/PRE-PROD/etc.

#### full-bkp.sh

No parameters are required. Review, edit, or even override the variable values to update this script.
Using `mariadb-backup` this script takes a full backup in a local directory (`/glide/mysql/backup`), then uses `rsync` to copy the backup to `/mnt/backup-dir/`. After a successful `rsync`, the backup file is deleted.

The backup itself uses `mbstream` to partially compress the InnoDB data before piping into `gzip` to provide more compression. If `pigz` is in path, then that will be used in place of `gzip`, which compresses data in parallel for a speed up.

#### restore-full.sh

WARNING! Running this script will delete all database data on the server!

The restore script takes only one parameter, the path to a backup file.
The script itself, stops MadiaDB, then deletes the contents of the `datadir` located at `/glide/mysql/data`.

Once the data is deleted, the backup is extracted by `gzip` and piped through `mbstream` to decompress the data.
As MariaDB is not running at this time, around 8GB of RAM is used to then run the `mariadb-backup --prepare` process to make the data ready.
Once completed, MariaDB is started.
If you are restoring a slave, you can check the `xtrabackup_info` file for the GTID when setting `gtid_slave_pos` when configuring replication.

NOTE: the file `xtrabackup_info` has a been renamed in later versions to `mariadb_backup_info`.

#### sync-binlogs.sh

Using `rsync`, the MariaDB binary logs are copied from `/glide/mysql/binlog` to `/mnt/backup-dir/binlog`. Before the sync starts, a `FLUSH BINARY LOGS` command is issued to MariaDB to close the current binlog file and being writing a new one.

Note, rsync is an archiving tool. It will not replace files unless it has to meaning it uses far less bandwitdh than simply using `cp`.

#### my

A wrapper around common commands. A more extensive and updated version is in `scripts/my`.
Use `my help` for more info.

### install-scripts.sh

In your current environment, scripts are copied from `/mnt/backup-dir/scripts` to `/usr/local/bin`.
Now you can easily edit the scripts on the backup mount, then copy them locally in one go.

#### cnf-backup.sh

Copies the `/my.cnf` MariaDB server config to `/mnt/backup-dir/configs`. An appropriate name is added to the file to identify when the file was copied and what host it originated from.

## Cronjobs

Cronjobs are defined **PER-USER**.

Examples [here](https://crontab.guru/examples.html)

View the cronjobs:

    crontab -l

Edit the cronjobs:

    crontab -e

Crontab layout:

    m h dom mon dow command
    * * * * * command to be executed
    – – – – –
    | | | | |
    | | | | +—– day of week (0 – 6) (Sunday=0)
    | | | +——- month (1 – 12)
    | | +——— day of month (1 – 31)
    | +———– hour (0 – 23)
    +————- min (0 – 59)

Run a job every 4 hours:

    0 */4 * * * /path/to/script.sh

On the first minute of every hour:

    0 * * * * /path/to/script.sh

At 0300 in the morning:

    0 3 * * * /path/to/script.sh

Once at the start of a month:

    0 * 1 * * /path/to/script.sh

## Replication Cheat Sheet

Required server variables in `/etc/my.cnf`:

    [mariadbd]
    log_bin = /path/to/binlog/dir/binlog-name-prefix
    log_slave_updates = 1 # Slaves maintain a copy of the logs. Needed for relay slaves and disaster recovery.
    server_id = X # A uniqute number per-server.

Always use [GTID](https://mariadb.com/kb/en/gtid/) replication across all servers when possible.

Get the GTID from a binlog name and position:

    SELECT BINLOG_GTID_POS("master-bin.000001", 600);

Show the local positions:

    SHOW GLOBAL VARIABLES LIKE '%gtid%';

**Convert** a server from file/pos to use GTID:

    STOP SLAVE;
    CHANGE MASTER TO master_host="127.0.0.1", master_use_gtid=current_pos;
    START SLAVE;

Change to **new master** on a slave when using GTID replication:
  
    STOP SLAVE;
    CHANGE MASTER TO master_host='127.0.0.1', master_port=3306;
    START SLAVE;

Set the local GTID and change master:

    SET GLOBAL gtid_slave_pos = "0-1-2";
    CHANGE MASTER TO master_host="127.0.0.1", master_port=3310, master_user="root", master_use_gtid=slave_pos;
    START SLAVE;
