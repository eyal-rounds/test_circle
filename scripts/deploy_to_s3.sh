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

fileWithPath=$(ls $CIRCLE_ARTIFACTS/apk/*release*.apk|grep -vi unaligned)
fileOnly=${file##*/}
echo "found file ${fileWithPath} to deploy"
echo "deploying ${fileWithPath} to s3://rounds-android-${bucketTag}/${fileOnly}"
aws s3 cp ${fileWithPath} s3://rounds-android-${bucketTag}/${fileOnly}
if [[ $? -eq 0 ]]
then
    echo "deploy success"
else
    echo "failed to deploy! exit code: $?"
fi