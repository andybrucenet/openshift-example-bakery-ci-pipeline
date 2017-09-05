#!/usr/bin/env bash

OC=${OC:-oc}

cd $(dirname $(realpath $0))
FOLDER=$(pwd)

echo "ARGS: $1"
if [[ $1 = delete-all ]]; then
    OS_DELETE_ALL=true
fi
if [[ $1 =~ delete ]]; then
    OS_DELETE_DEPLOYMENT=true
fi
if [[ $1 =~ build ]]; then
    OS_BUILD_ONLY=true
fi

TEMPLATE_DEPLOY=$FOLDER/citrus-test.yml
count=0

function deployOpenshiftObject(){
    app_name=$1
    echo "CREATE DEPLOYMENT for $app_name"
    $OC delete pods -l "application=$app_name"  --grace-period=0
    echo ".... " && sleep 2
    $OC process -f "$TEMPLATE_DEPLOY" \
        -v CITRUS_TEST_NAME=$app_name \
        | $OC apply -f -

    $FOLDER/../sakuli-tests/validate_pod-state.sh $app_name
    exitcode=$?
    echo "-------------------------------------------------------------------"
    exit $exitcode
}

function deleteOpenshiftObject(){
    app_name=$1
    echo "DELETE Config for $app_name"
    $OC delete dc -l "application=$app_name"  --grace-period=5
    $OC delete deployment -l "application=$app_name"  --grace-period=5
    $OC delete pods -l "application=$app_name"  --grace-period=5
    $OC delete service -l "application=$app_name"  --grace-period=5
    $OC delete route -l "application=$app_name"  --grace-period=5
    echo "-------------------------------------------------------------------"

}


function triggerOpenshift() {
    echo "--------------------- APP $count ---------------------------------------"
    if [[ $OS_DELETE_DEPLOYMENT == "true" ]]; then
        deleteOpenshiftObject $SER_NAME
    else
        deployOpenshiftObject $SER_NAME
    fi
    echo "-------------------------------------------------------------------"
    ((count++))

}
SER_NAME=citrus-test
triggerOpenshift

wait
exit $?
