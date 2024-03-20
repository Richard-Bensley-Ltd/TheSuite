# TIPS

## Doc links

* [Knowledge Base](https://mariadb.com/kb/en/)

## Books

* High Performance MySQL, https://www.amazon.co.uk/High-Performance-MySQL-Strategies-Running/dp/1492080519/
* Mastering MariaDB, https://www.packtpub.com/product/mastering-mariadb/9781783981540
* MariaDB High Performance, https://www.amazon.co.uk/MariaDB-High-Performance-Pierre-MAVRO/dp/1783981601

## Logs

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

## Data Accuracy and Safety

Once upon a time some [hero](https://jira.mariadb.org/browse/MDEV-7635) made sure MariaDB was safe, simple, and ACID compliant by default.

Atomic, Consistent, Isolated, Durable.
The data that goes in, is the data that comes out again.

* `innodb_flush_log_at_trx=1`
* `sync_binlog=1`
* `sql_mode=STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION`, all settings are [here](https://mariadb.com/kb/en/server-system-variables/#sql_mode)

## Replication

Replication options:

* Asynchronous replication, the most prelevant option.
* Semi-Synchronous replication, enabled via a plugin, will only complete a transaction when at least one slave has received the change.
* Galera, two phase commits, shared everything self-healing cluster.

## Failover

Choose a solution to first of all make application switchers seemless by using a proxy service, or a virtual IP.

Other solutions common for use with MariaDB include:

* Maxscale, Enterprise license required.
* ProxySQL, open source.
* HAProxy, not database aware but it is open source.

Only Maxscale can handle master promotion and something close to automatic failover. All other solutions require custom tooling.

