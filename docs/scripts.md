# Scripts

## Variable overrides

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

## Per-Environment settings

Scripts which have paths to the backup mounts including `install-scripts.sh`, `full-bkp.sh`, and `sync-binlogs.sh` have different paths to where the backups are located between PROD/PRE-PROD/etc.


## full-bkp.sh

No parameters are required. Review, edit, or even override the variable values to update this script.
Using `mariadb-backup` this script takes a full backup in a local directory (`/glide/mysql/backup`), then uses `rsync` to copy the backup to `/mnt/backup-dir/`. After a successful `rsync`, the backup file is deleted.

The backup itself uses `mbstream` to partially compress the InnoDB data before piping into `gzip` to provide more compression. If `pigz` is in path, then that will be used in place of `gzip`, which compresses data in parallel for a speed up.

## restore-full.sh

WARNING! Running this script will delete all database data on the server!

The restore script takes only one parameter, the path to a backup file.
The script itself, stops MadiaDB, then deletes the contents of the `datadir` located at `/glide/mysql/data`.

Once the data is deleted, the backup is extracted by `gzip` and piped through `mbstream` to decompress the data.
As MariaDB is not running at this time, around 8GB of RAM is used to then run the `mariadb-backup --prepare` process to make the data ready.
Once completed, MariaDB is started.
If you are restoring a slave, you can check the `xtrabackup_info` file for the GTID when setting `gtid_slave_pos` when configuring replication.

NOTE: the file `xtrabackup_info` has a been renamed in later versions to `mariadb_backup_info`.

## sync-binlogs.sh

Using `rsync`, the MariaDB binary logs are copied from `/glide/mysql/binlog` to `/mnt/backup-dir/binlog`. Before the sync starts, a `FLUSH BINARY LOGS` command is issued to MariaDB to close the current binlog file and being writing a new one.

Note, 


## my

A wrapper around common commands. A more extensive and updated version is in `scripts/my`.
Use `my help` for more info.

## install-scripts.sh

In your current environment, scripts are copied from `/mnt/backup-dir/scripts` to `/usr/local/bin`.
Now you can easily edit the scripts on the backup mount, then copy them locally in one go.

## cnf-backup.sh

Copies the `/my.cnf` MariaDB server config to `/mnt/backup-dir/configs`. An appropriate name is added to the file to identify when the file was copied and what host it originated from.


