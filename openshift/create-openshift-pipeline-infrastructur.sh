#!/usr/bin/env bash
set -e

OC=${OC:-oc}

cd $(dirname $(realpath $0))
FOLDER=$(pwd)
echo "ARGS: $1"

function checkDefaults(){
    if [ -z $PROJECT_BASENAME ]; then
        export PROJECT_BASENAME='ta-pipeline'
    fi
}
checkDefaults

if [[ $1 =~ delete ]]; then
    echo "============= DELETE PROJECTS =================="
    $OC delete project "${PROJECT_BASENAME}-dev"
    $OC delete project "${PROJECT_BASENAME}-qa"
    $OC delete project "${PROJECT_BASENAME}-prod"
    exit 0
fi

echo "============= prepare DEV stage =================="
$OC new-project "${PROJECT_BASENAME}-dev"

$OC create sa cd-agent
$OC policy add-role-to-user admin -z cd-agent
echo "SA_TOKEN"
$OC serviceaccounts get-token cd-agent

echo "============= prepare QA stage =================="
$OC new-project "${PROJECT_BASENAME}-qa"
#$OC process -f project/app-secrets.yml -p PROJECT_BASENAME="${PROJECT_BASENAME}" -p BASE_ROUTE_URL="${BASE_ROUTE_URL}" -o yaml | $OC apply -f -
$OC policy add-role-to-user admin system:serviceaccount:${PROJECT_BASENAME}-dev:cd-agent
$OC policy add-role-to-user admin system:serviceaccount:${PROJECT_BASENAME}-dev:jenkins

echo "============= prepare PROD stage =================="
$OC new-project "${PROJECT_BASENAME}-prod"
#$OC process -f project/app-secrets.yml -p PROJECT_BASENAME="${PROJECT_BASENAME}" -p BASE_ROUTE_URL="${BASE_ROUTE_URL}" -o yaml | $OC apply -f -
$OC policy add-role-to-user admin system:serviceaccount:${PROJECT_BASENAME}-dev:cd-agent
$OC policy add-role-to-user admin system:serviceaccount:${PROJECT_BASENAME}-dev:jenkins

echo "============= configure DEV stage =================="
$OC project "${PROJECT_BASENAME}-dev"
$OC policy add-role-to-group system:image-puller system:serviceaccounts:${PROJECT_BASENAME}-qa
$OC policy add-role-to-group system:image-puller system:serviceaccounts:${PROJECT_BASENAME}-prod

$FOLDER/infrastructur/create-infrastrutur.sh
echo "finished!"
