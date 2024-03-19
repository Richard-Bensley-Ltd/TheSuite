#!/usr/bin/env bash

print_usage() {
    echo -e "$0 src_dir/ dest_dir"
}


if [[ $# -ne 2 ]]
then
    echo "Need a source and a destination directory"
    print_usage
    exit 1
fi

SRC_DIR="${1}"
DEST_DIR="${2}"
if [[ ! -d ${SRC_DIR} ]]
then
    echo "Cannot access source directory, ${SRC_DIR}"
    exit 1
fi

if [[ ! -d ${DEST_DIR} ]]
then
    echo "Cannot access destination directory, ${DEST_DIR}"
    exit 1
fi

# Trim any tailing slashes from both variables
T_SRC_DIR=$(echo "$SRC_DIR" | sed 's:/*$::')
T_DEST_DIR=$(echo "$DEST_DIR" | sed 's:/*$::')

# Specifically add a trailing slash to the source
echo -e "2024-03-19_09-14-01\tINFO: Starting sync from ${T_SRC_DIR} to ${T_DESC_DIR}" && \
rsync -av ${T_SRC_DIR}/ ${T_DEST_DIR}
