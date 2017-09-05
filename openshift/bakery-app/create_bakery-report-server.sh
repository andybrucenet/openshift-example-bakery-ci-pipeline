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
if [ -z  $NEXUS_HOST ]; then
    NEXUS_HOST="nexus-ta-nexus.127.0.0.1.nip.io"
fi


TEMPLATE_BUILD=$FOLDER/openshift.build.bakery.generic.yaml
TEMPLATE_DEPLOY=$FOLDER/openshift.deploy.web.yaml

BUILD_DOCKERFILE='Dockerfile.report'
PROBE_PATH='/report'
SER_NAME='bakery-report-server'

count=0


function deployOpenshiftObject(){
    app_name=$1
    echo "CREATE DEPLOYMENT for $app_name"
    $OC process -f "$TEMPLATE_DEPLOY" \
        -v APP_NAME=$app_name \
        -v IMAGE_STREAM=$app_name \
        -v PROBE_PATH=$PROBE_PATH \
        | $OC apply -f -
    echo ".... " && sleep 2
    $OC get all -l application=$app_name
    echo "-------------------------------------------------------------------"

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

function buildOpenshiftObject(){
    app_name=$1
    echo "Trigger Build for $app_name"
    $OC delete builds -l application=$app_name

    $OC process -f "$TEMPLATE_BUILD" \
        -v APP_NAME=$app_name \
        -v SOURCE_DOCKERFILE=$BUILD_DOCKERFILE \
        -v NEXUS_HOST=$NEXUS_HOST \
        -v UPDATED="$(date +%Y-%m-%d_%H:%M:%S)" \
        | $OC apply -f -
    $OC start-build "$app_name" --follow --wait
    exit $?
}
function buildDeleteOpenshiftObject(){
    app_name=$1
    echo "Trigger DELETE Build for $app_name"
    $OC process -f "$TEMPLATE_BUILD" \
        -v APP_NAME=$app_name \
        -v SOURCE_DOCKERFILE=$BUILD_DOCKERFILE \
        | $OC delete -f -
    echo "-------------------------------------------------------------------"
}


function triggerOpenshift() {
    echo "--------------------- APP $count ---------------------------------------"
    if [[ $OS_BUILD_ONLY == "true" ]]; then
        buildOpenshiftObject  $SER_NAME
    elif [[ $OS_DELETE_DEPLOYMENT == "true" ]]; then
        deleteOpenshiftObject $SER_NAME
        if [[ $OS_DELETE_ALL == "true" ]]; then
            buildDeleteOpenshiftObject $SER_NAME
        fi
    else
        deployOpenshiftObject $SER_NAME
    fi
    echo "-------------------------------------------------------------------"
    ((count++))

}

triggerOpenshift

wait
exit $?
