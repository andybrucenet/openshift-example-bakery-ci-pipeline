#!/usr/bin/env bash

OC=${OC:-oc}

cd $(dirname $(realpath $0))
FOLDER=$(pwd)

echo "ARGS: $1 $2 $3"

SOURCE_STAGE=$1
TARGET_STAGE=$2
IMAGE_NAME=$3
PROJECT_PREFIX=ta-pipeline

echo "source stage: $SOURCE_STAGE"
echo "target stage: $TARGET_STAGE"
echo "IMAGE: $IMAGE_NAME"
echo "PROJECT_PREFIX: $PROJECT_PREFIX"

$OC tag "$PROJECT_PREFIX-$SOURCE_STAGE/$IMAGE_NAME" "$PROJECT_PREFIX-$TARGET_STAGE/$IMAGE_NAME"
exit $?
