#!/usr/bin/env bash

if [[ -z $1 ]]
then
    SLEEPTIME=3
else
    SLEEPTIME=${1}
fi

if [[ -z $2 ]]
then
    LIMIT=10000
else
    LIMIT=$2
fi

counter=0

while true
do
    mariadb -NBe "INSERT INTO test.slow_test (c,d) VALUES ('rand text ${counter}', RAND());"
    counter=$((counter+1))
    echo -en "$(date)\t${counter} inserts\r"
    if [[ $counter -ge $LIMIT ]]
    then
        echo "Limit reached: ${counter}"
        exit 0
    fi
done

