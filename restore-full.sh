#!/usr/bin/env bash

DATADIR="${DATADIR:=/glide/mysql/data}"
USE_MEMORY="${USE_MEMORY:=8G}"

print_usage() {
    echo -e "ERROR\tNeed a backup file and a directory to extract to."
    echo -e "Usage example:"
    echo -e "$0 /path/to/backup/file /path/extract/to"
}

if [[ $# -ne 2 ]]
then
    print_usage
    exit 1
fi

BACKUP_FILE=${1}
TARGET_DIR=${2}

echo -e "Creating ${TARGET_DIR} if it does not exist"
mkdir -p ${TARGET_DIR}
if [[ ! -d ${TARGET_DIR} ]]
then
    echo -e "ERROR\t${TARGET_DIR} directory does not exist"
    exit 1
fi

echo -e "INFO\tStarting extraction of ${BACKUP_FILE} to ${TARGET_DIR}..."
gunzip -c "${BACKUP_FILE}" | mbstream -x --directory=${TARGET_DIR} && \
    echo -e "INFO\tStopping MariaDB" && \
    systemctl stop mariadb && \
    echo -e "INFO\tPreparing backup with ${USE_MEMORY} of memory" && \
    mariadb-backup --use-memory=${USE_MEMORY} --prepare --target-dir=${TARGET_DIR} && \
    echo -e "INFO\tDeleting datadir contents from ${DATADIR}" && \
    rm -Rf ${DATADIR}/* && \
    echo -e "INFO\tCopying back to datadir ${DATADIR}" && \
    mariadb-backup --copy-backup --target-dir=${TARGET_DIR} && \
    echo -e "INFO\tChanging permissions on datadir ${DATADIR}" && \
    chown -R mysql:mysql ${DATADIR} && \
    echo -e "INFO\tStarting MariaDB" && \
    systemctl start mariadb && \
    echo -e "INFO\tRemoving backup files" && \
    rm -Rf ${TARGET_DIR}/* && \
    echo -e "INFO\tRestore completed" && \
    exit 0
