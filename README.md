# MariaDB Enterprise Tools

Tooling for common tasks including backup, restore, replication, and monitoring.

## Requirements

* Python 3.5 and above.
* The `pymysql` library available as `pymysql` from `pip`, or `python3-pymysql` from `apt`, or `python3-PyMySQL` from `yum`/`dnf`.
* A valid [option](https://mariadb.com/kb/en/configuring-mariadb-with-option-files/) file with client details. The default location is `~/.my.cnf`

## The Tools Suite

* `mdb-post-install.sh`, for setting up and configuring MariaDB entperise after an `RPM`, `deb` or repository sourced install.
* `mdb-backup.py`, backup MariaDB Enterprise.
* `mdb-restore.py`, restore an instance of MariaDB Enterprise.
* `mdb-mon.py`, background monitor and status command.

### mdb-post-install.sh

### mdb-backup.py

The backup tool is designed to run on the server being backed up.

Perform a full backup of the local MariaDB server

### mdb-restore.py

The restore tool is designed to be run from the server being restored. When using incremental or differential restores, it is best if the backup paths or mounts are directly accessible by this tool.

Perform a full restore:

    mdb-restore.py restore

TODO

### mdb-mon.py

TODO
