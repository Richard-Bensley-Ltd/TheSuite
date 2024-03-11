#!/bin/bash

set -e # exit on errors

#
# Check server is a master and not a slave
#

# Slaves connected?
SLAVES_CONNECTED=$(mariadb -NBe "select variable_value from information_schema.global_variables where variable_name='slaves_connected'")
if [[ $SLAVES_CONNECTED -gt 0 ]]
then
    echo -e "INFO\tSLaves Connected: ${SLAVES_CONNECTED}"
else
    echo -e "INFO\tNo slaves Connected (${SLAVES_CONNECTED}) exiting"
fi

# Slave threads running?
SLAVES_RUNNING=""
for i in $(mariadb -E -Be "show slave status" |  awk '{$1=$1,print}' | egrep -i 'slave_sql_running:|slave_io_running' | cut -d" " -f 2)
do
if [[ "${i}" = "Yes" ]]
    then
        SLAVES_RUNNING="${i}"
        echo -e "INFO\tA slave thread is running, existing"
        exit 0
    fi
done

# Not slave, continuing

BACKUP_PREFIX="${BACKUP_PREFIX:=full-bkp}"
BACKUP_ROOT="${BACKUP_ROOT:=/glide/mysql/backup}"
BACKUP_MOUNT="${BACKUP_MOUNT:=/mnt/db_backup_share/servicenow}"
BACKUP_DATE="${BACKUP_DATE:=$(date +'%d%m%Y-%H%M%S')}"
BACKUP_NAME="${BACKUP_NAME:=${BACKUP_PREFIX}-${BACKUP_DATE}}"
BACKUP_FILE="${BACKUP_FILE:=${BACKUP_ROOT}/${BACKUP_NAME}.gz}"
BACKUP_MOUNT_FILE="${BACKUP_MOUNT_FILE:=${BACKUP_MOUNT}/${BACKUP_NAME}.gz}"
BACKUP_MIN_SIZE=${BACKUP_MIN_SIZE:=1} # 100GB
BACKUP_DAYS_MAX=${BACKUP_DAYS_MAX:=7}
BACKUP_THREADS=${BACKUP_THREADS:=4}

GZIP_BIN=pigz

if which $GZIP_BIN >/dev/null 2>&1 /dev/null;
then
    echo -e "INFO\tFound pigz in PATH"
else
    echo -e "WARNING\tpigz not in PATH, using gzip"
    GZIP_BIN=gzip
fi

if [[ ! -d ${BACKUP_ROOT} ]]
then
    echo -e "ERROR\tBackup ROOT does exist: ${BACKUP_ROOT}"
    exit 1
fi

if [[ ! -d ${BACKUP_MOUNT} ]]
then
    echo -e "ERROR\tBackup MOUNT does exist: ${BACKUP_MOUNT}"
    exit 1
fi

echo -e "INFO\tStarting Backup to ${BACKUP_FILE}"
mariadb-backup --user=$USER --backup --stream=mbstream | $GZIP_BIN > ${BACKUP_FILE}

if [[ ! -f ${BACKUP_FILE} ]]
then
    echo -e "ERROR\t${BACKUP_FILE} not created"
    ex1t 1
fi

if [[ $(stat -c "%s" ${BACKUP_FILE}) -lt ${BACKUP_MIN_SIZE} ]]
then
    echo -e "ERROR\tthe backup file ${BACKUP_FILE} is less than ${BACKUP_MIN_SIZE} bytes"
    rm -f ${BACKUP_FILE}
    exit 1
fi

echo -e "INFO\tMoving ${BACKUP_FILE} to ${BACKUP_MOUNT_FILE}"
rsync -r ${BACKUP_FILE} ${BACKUP_MOUNT_FILE} && rm -f ${BACKUP_FILE}
if [[ ! -f ${BACKUP_MOUNT_FILE} ]]
then
    echo -e "ERROR\tThe backup file could not be moved to ${BACKUP_MOUNT_FILE}"
    exit 1
fi

# Cleanup backups
BACKUP_COUNT=$(find ${BACKUP_MOUNT} -type f -name "${BACKUP_PREFIX}-*\.gz" | wc -l)
echo -e "INFO\t${BACKUP_COUNT} backup files in ${BACKUP_MOUNT}"
if [[ $BACKUP_COUNT -gt 1 ]]; then
        echo -e "INFO\tLooking for backup files to be removed..."
        find ${BACKUP_ROOT} -type f -name "${BACKUP_PREFIX}-*\.gz" -mtime +${BACKUP_DAYS_MAX} -exec rm {} \;
fi
# Summary
echo -e "INFO\tFiles in ${BACKUP_MOUNT}:"
ls -aslh ${BACKUP_MOUNT}/
echo -e "INFO\tBackup ROOT size: $(du -sh ${BACKUP_MOUNT})"

exit 0
