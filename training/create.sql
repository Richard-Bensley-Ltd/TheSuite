CREATE DATABASE IF NOT EXISTS test;
USE test;
CREATE TABLE IF NOT EXISTS t1 (
    a INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    b TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=INNODB;

INSERT INTO test.t1 (a) SELECT seq FROM seq_1_to_999;

GRANT ALL PRIVILEGES ON *.* TO 'mariabackup'@'%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON *.* TO 'dba'@'%' IDENTIFIED BY 'dba';

