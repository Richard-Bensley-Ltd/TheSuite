#!/bin/bash

set -e # exit on errors

#
# Check server is a master and not a slave
#

# Slaves connected?
SLAVES_CONNECTED=$(mariadb -NBe "select variable_value from information_schema.global_variables where variable_name='slaves_donnected'")
if [[ $SLAVES_CONNECTED -gt 0 ]]
then
    echo "INFO SLaves Connected: ${SLAVES_CONNECTED}"
else
    echo "INFO No slaves Connected (${SLAVES_CONNECTED}) exiting"
fi

# Slave threads running?
SLAVES_RUNNING=""
for i in $(mariadb -E -Be "show slave status" |  awk '{$1=$1,print}' | egrep -i 'slave_sql_running:|slave_io_running' | cut -d" " -f 2)
do
if [[ "${i}" = "Yes" ]]
    then
        SLAVES_RUNNING="${i}"
    fi
done

if [[ ${SLAVES_RUNNING} = "Yes" ]]
then
    echo "INFO Slave threads are running, exiting"
    exit 0
fi

BACKUP_PREFIX="${BACKUP_PREFIX:=full-blk}"
BACKUP_ROOT="${BACKUP_ROOT:=/glide/mysql/backup}"
BACKUP_MOUNT="${BACKUP_MOUNT:=/mnt/db_backup_share/servicenow}"
BACKUP_DATE="${BACKUP_DATE:=$(date +'%d%m%Y-%H%M%S')}"
BACKUP_NAME="${BACKUP_NAME:=${BACKUP_PREFIX}-${BACKUP_DATE}}"
BACKUP_FILE="${BACKUP_FILE:=${BACKUP_ROOT}/${BACKUP_NAME}.gz}"
BACKUP_MOUNT_FILE="${BACKUP_MOUNT_FILE:=${BACKUP_MOUNT}/${BACKUP_NAME}.gz}"
BACKUP_MIN_SIZE=${BACKUP_MIN_SIZE:=100000000000} # 100GB
BACKUP_DAYS_MAX=${BACKUP_DAYS_MAX:=7}

if [[ ! -d ${BACKUP_ROOT} ]]
then
    echo "ERROR Backup root does exist ${BACKUP_ROOT}"
    exit 1
fi

if [[ ! -d ${BACKUP_MOUNT} ]]
then
    echo "ERROR Backup mount does exist ${BACKUP_MOUNT}"
    exit 1
fi

echo "Starting Backup to ${BACKUP_FILE}"
mariadb-backup --backup --stream=mbstream | gzip > ${BACKUP_FILE}

if [[ ! -f ${BACKUP_FILE} ]]
then
    echo "ERROR ${BACKUP_FILE} not created"
    ex1t 1
fi

if [[ $(stat -c "%s" ${BACKUP_FILE}) -lt ${BACKUP_MIN_SIZE} ]]
then
    echo "ERROR the backup file ${BACKUP_FILE} is less than ${BACKUP_MIN_SIZE} bytes"
    rm -f ${BACKUP_FILE}
    exit 1
fi

echo "Moving ${BACKUP_FILE} to ${BACKUP_MOUNT_FILE}"
rsync -r ${BACKUP_FILE} ${BACKUP_MOUNT_FILE} && rm -f ${BACKUP_FILE}
if [[ ! -f ${BACKUP_MOUNT_FILE} ]]
then
    echo "ERROR the backup file could not be moved to ${BACKUP_MOUNT_FILE}"
    exit 1
fi

# Cleanup backups
BACKUP_COUNT=$(find ${BACKUP_ROOT} -type f -name "full-bkp-*\.gz" | wc -l)
if [[] $BACKUP_COUNT -gt 1 ]]; then
        echo "INFO removing old backup(s)"
        find ${BACKUP_COUNT} -type f -name "full-bkp-*\.gz" -mtime +${BACKUP_DAYS_MAX} -exec rm {} \;
        ls -aslh ${BACKUP_ROOT}
        du -sh ${BACKUP_ROOT}
fi
