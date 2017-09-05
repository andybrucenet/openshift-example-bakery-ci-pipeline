#!/usr/bin/env bash

OC=${OC:-oc}

cd $(dirname $(realpath $0))
FOLDER=$(pwd)
echo "ARGS: $1"

if [ -z  $NEXUS_HOST ]; then
    #local openshift
    #IMAGE_PREFIX='172.30.1.1:5000'
    NEXUS_HOST="nexus-ta-nexus.127.0.0.1.nip.io"
    #consol nexus
    #NEXUS_HOST="nexus-ta-nexus.paasint.consol.de"
fi

if [ -z $IMAGE_REG ]; then
    #local openshift
    IMAGE_PREFIX='172.30.1.1:5000'
    #consol openshift
    #IMAGE_REG='172.30.19.12:5000'
fi

if [[ $1 =~ delete ]]; then
    echo "============= DELETE INFRASTRUCTUR =================="
    $OC process -f $FOLDER/jenkins.yml \
        -v NEXUS_HOST=${NEXUS_HOST} \
        -v IMAGE_REG=${IMAGE_REG} \
        | $OC delete -f -
    echo "tried to delete not persistent content"
    if [[ $1 =~ delete-all ]]; then
        $OC process -f $FOLDER/jenkins.persistent.yml | $OC delete -f -
        echo "tried to delete persistent content"
    fi
    exit 0
fi

echo "============= CREATE INFRASTRUCTUR =================="
echo "NEXUS_HOST=${NEXUS_HOST}"
echo "IMAGE_REG=${IMAGE_REG}"

$OC process -f $FOLDER/jenkins.persistent.yml | $OC apply -f - \
    && $OC process -f $FOLDER/jenkins.yml \
            -v NEXUS_HOST=${NEXUS_HOST} \
            -v IMAGE_REG=${IMAGE_REG} \
            | $OC apply -f -
