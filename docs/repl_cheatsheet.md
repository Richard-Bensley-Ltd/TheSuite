# Replication Cheat Sheet

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
    CHANGE MASTER TO master_host='127.0.0.1', master_port=3312;
    START SLAVE;


## Sources

* [https://mariadb.com/kb/en/gtid/](https://mariadb.com/kb/en/gtid/)
* 