#!/bin/bash

if [[ "$CIRCLE_BRANCH" == "master" ]]
then
    bucketTag=release
elif [[ "$CIRCLE_BRANCH" == "develop" ]]
then
    bucketTag=develop
else
    echo "not on main branches (master\develop) will not deploy"
    exit 0
fi

file=$(ls $CIRCLE_ARTIFACTS/apk/*release*.apk|grep -vi unaligned)
echo "found file ${file} to deploy"
echo "deploying ${file} to s3://rounds-android-${bucketTag}/${file}"
aws s3 cp ${file} s3://rounds-android-${bucketTag}/${file}
if [[ $? -eq 0 ]]
then
    echo "deploy success"
else
    echo "failed to deploy! exit code: $?"
fi