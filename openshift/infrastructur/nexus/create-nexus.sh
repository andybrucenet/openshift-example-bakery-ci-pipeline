#!/usr/bin/env bash

OC=${OC:-oc}

cd $(dirname $(realpath $0))
FOLDER=$(pwd)
echo "ARGS: $1"

echo "============= USE PROJECT NEXUS =================="
${OC} project ta-nexus
if [[ $1 =~ delete ]]; then
    echo "============= DELETE NEXUS =================="
    ${OC} process -f $FOLDER/nexus2-persistent-template.yaml | ${OC} delete -f -
    exit $?
fi

echo "============= CREATE NEXUS =================="
${OC} process -f $FOLDER/nexus2-persistent-template.yaml | ${OC} apply -f -
#    && oc process -f $FOLDER/nexus.yml | oc apply -f -
