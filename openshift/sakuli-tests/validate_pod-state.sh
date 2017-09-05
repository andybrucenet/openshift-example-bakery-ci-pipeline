#!/usr/bin/env bash

OC=${OC:-oc}

#set -x
cd $(dirname $(realpath $0))
FOLDER=$(pwd)

echo "ARGS: $1"
count=0
maxval=100
sleeper=5

SER_NAME=$1

function validate() {
    state=""
    while  [[ $state != "Terminated" ]] && [ $count -lt $maxval ]; do
        echo "--------------------- Validate $count ---------------------------------------"
        echo ".... retry in $sleeper sec" && sleep $sleeper
        state=$($OC describe pod $SER_NAME --show-events=false | grep 'State:' |  awk '{print $2}')
        echo "$SER_NAME state=$state"
        ((count++))
    done;
    echo "-------------------------------------------------------------------"
    $OC logs $SER_NAME
    echo "-------------------------------------------------------------------"
    if [ $count -ge $maxval ]; then
        echo "count $count reached max val of retries: $maxval"
        $OC delete pod $SER_NAME
        exitcode=-1
    else
        exitcode=$($OC describe pod $SER_NAME --show-events=false | grep 'Exit Code:' |  awk '{print $3}')
    fi
    echo "EXIT_CODE: $exitcode"

    #onyl on running containers possible :-(
    #$OC rsync "$SER_NAME":/headless/sakuli/bakery/$SER_NAME/\*\*/_logs $FOLDER/
    exit $exitcode

}

validate

wait
exit $?
