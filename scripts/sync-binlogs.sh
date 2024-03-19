#!/usr/bin/env bash

set -e # exit on errors

#
# Check server is a master and not a slave
#

# Slaves connected?
SLAVES_CONNECTED=$(mariadb -NBe "select variable_value from information_schema.global_status where variable_name='slaves_connected'")
if [[ $SLAVES_CONNECTED -gt 0 ]]
then
    echo -e "$(date +'%F_%H-%M-%S')\tINFO\tSlaves Connected: ${SLAVES_CONNECTED}"
else
    echo -e "$(date +'%F_%H-%M-%S')\tINFO\tNo slaves Connected (${SLAVES_CONNECTED}) exiting"
    exit 0
fi

# Slaves running?
SLAVES_RUNNING=$(mariadb -NBe "select variable_value from information_schema.global_status where variable_name='slaves_running'")
if [[ $SLAVES_RUNNING != "OFF" ]]
then
    echo -e "$(date +'%F_%H-%M-%S')\tINFO\tSlaves Running: ${SLAVES_RUNNING}"
    exit 0
fi

# Not slave, continuing

SRC_DIR="/glide/mysql/binlog"
DEST_DIR="/mnt/mariadb_backup_share/binlog"
if [[ $# -eq 2 ]]
then
    SRC_DIR="${1}"
    DEST_DIR="${2}"
fi

if [[ ! -d ${SRC_DIR} ]]
then
    echo -e "$(date +'%F_%H-%M-%S')\tERROR: Cannot access source directory, ${SRC_DIR}"
    exit 1
fi

if [[ ! -d ${DEST_DIR} ]]
then
    echo -e "$(date +'%F_%H-%M-%S')\tERROR: Cannot access destination directory, ${DEST_DIR}"
    exit 1
fi

# Trim any tailing slashes from both variables
# A trailing slash is added to the source when rsync runs.
T_SRC_DIR=$(echo "$SRC_DIR" | sed 's:/*$::')
T_DEST_DIR=$(echo "$DEST_DIR" | sed 's:/*$::')

# Flush the binary logs so the current log file is closed and a new file is opened
echo -e "$(date +'%F_%H-%M-%S')\tINFO: Flushing binary logs"
mariadb -NBe "FLUSH BINARY LOGS"
if [[ $? -ne 0 ]]
then
    echo -e "$(date +'%F_%H-%M-%S')\tERROR: Failed to flush binary logs!"
    exit 1
fi

# Start the sync
echo -e "$(date +'%F_%H-%M-%S')\tINFO: Starting sync from ${SRC_DIR}/ to ${DEST_DIR}"
rsync -av ${T_SRC_DIR}/ ${T_DEST_DIR}
if [[ $? -ne 0 ]]
then
    echo -e "$(date +'%F_%H-%M-%S')\tERROR: Sync FAILED from ${T_SRC_DIR} to ${T_DESC_DIR}"
    exit 1
fi

echo -e "$(date +'%F_%H-%M-%S')\tINFO: Finished sync" && \
exit 0
