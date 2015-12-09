#!/bin/bash

APP_DIR=app
BRANCH_FOR_VERSION_COUNT=$BRANCH_WITH_COUNTER

#if it's not the branch we want to use counter in, exit now
if [[ "CIRCLE_BRANCH" != "$BRANCH_FOR_VERSION_COUNT" ]]
then
    exit 0
fi

#build the chache dir
if [[ ! -d ~/.rounds_cache/ ]]
then
    mkdir -p ~/.rounds_cache/
fi
#get current version name from the gradle file.
curr_ver=$(cat ${APP_DIR}/build.gradle |grep versionName|tr -d ' \t'|sed -e 's/ *versionName *\"\(.*\)\"/\1/g')
if [[ ! -f ~/.rounds_cache/version_name ]]
then
    echo $curr_ver > ~/.rounds_cache/version_name
fi
#get the cached version name
cached_ver=$(cat ~/.rounds_cache/version_name|tr -d ' \t')
# if no build count file OR new app version name restart the count.
if [[ "$ver" != "$cached_ver" ]] || [[ ! -f ~/.rounds_cache/build_count ]]
then
    echo \0 > ~/.rounds_cache/build_count
else
    #if we already have build count file, increase it by one for the build process.
    count=$(cat ~/.rounds_cache/build_count|tr -d ' \t')
    echo $((count+1))> ~/.rounds_cache/build_count
fi
#if it's just new version also cache the new version name
if [[ "$ver" != "$cached_ver" ]]
then
    echo $curr_ver > ~/.rounds_cache/version_name
fi
