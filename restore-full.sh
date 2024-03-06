#!/usr/bin/env bash

print_usage() {
    echo "ERROR Need a backup file and a directory to extract to."
    echo "Usage example:"
    echo "$0 /path/to/backup/file /path/extract/to"
}

if [[ $# -ne 2 ]]
then
    print_usage
    exit 1
fi

echo "Starting extraction of ${1} to ${2}..."
if [[ ! -d ${2} ]]
then
    echo "ERROR ${2} directory does not exist"
    exit 1
fi

cd ${2} && gunzip -c "${1}" | mbstream -x
