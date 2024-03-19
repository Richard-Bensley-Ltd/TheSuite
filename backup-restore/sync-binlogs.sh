#!/usr/bin/env bash

if [[ $# -ne 2 ]]
then
    echo -e "$(date +'%F_%H-%M-%S')\tERROR: Need a source and a destination directory"
    echo -e "USAGE: $0 src_dir/ dest_dir"
    exit 1
fi

SRC_DIR="${1}"
DEST_DIR="${2}"
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

# Start
echo -e "$(date +'%F_%H-%M-%S')\tINFO: Starting sync from ${SRC_DIR}/ to ${DESC_DIR}"

# Trim any tailing slashes from both variables
T_SRC_DIR=$(echo "$SRC_DIR" | sed 's:/*$::')
T_DEST_DIR=$(echo "$DEST_DIR" | sed 's:/*$::')

# Specifically add a trailing slash to the source
rsync -a ${T_SRC_DIR}/ ${T_DEST_DIR} && \
    echo -e "$(date +'%F_%H-%M-%S')\tINFO: Finished sync" && \
    exit 0 || echo -e "$(date +'%F_%H-%M-%S')\tERROR: Sync FAILED from ${T_SRC_DIR} to ${T_DESC_DIR}" && exit 1T
