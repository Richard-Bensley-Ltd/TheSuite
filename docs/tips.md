# TIPS

## Doc links

* Knowledge Base
* Knowledge Base PDF
* Mariadb.com Enterprise docs (crap)

## Books

* High Performance MySQL

## Logs

|Name|Variable|Plugin?|Notes|
|Error Log|`log_error`|No|When not set it logs to stdout/journal|
|Slow Log|`slow_query_log_%`|No||
|General Log||


|Log Variable|Recommended Setting|Notes|
|log_output|FILE|TABLE or FILE,TABLE can be used to have the general and slow logs goto a table in the `mysql` schema|
|log_base_name|||

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
