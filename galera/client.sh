#!/usr/bin/env bash

if [[ -z $1 ]]
then
    SLEEPTIME=3
else
    SLEEPTIME=${1}
fi

counter=0

while true
do
    mariadb -P 3307 -udba -pdba -NBe "INSERT INTO test.t1 () VALUES ();"
    counter=$((counter+1))
    echo -en "$(date)\t${counter} inserts\r"
    sleep ${SLEEPTIME}
done
