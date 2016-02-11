#!/bin/bash  

function showHelp(){
    echo -e "help: command construct is \n$0 [version name]"
    echo "example: $1 5.3.1"
}

function validateCleanGitOrExit(){
	local isClean=$(git status|grep -c "nothing to commit")
	if [[ ${isClean} -eq 0 ]] ;
	then
		echo "workspace is not clean! we need clean slate to create a release branch"
		git status
		exit 1
	fi
}

function validateOnDevelopBranchOrExit(){
	local branchName=$(git name-rev --name-only HEAD)
    if [[ "${branchName}" != "develop" ]] ;
    then
		echo "you MUST BE on develop branch to create a new release branch."
		echo "please do: % git checkout develop and re-run this script"
		exit 1
    fi
}

function changeVersionName(){
	basedir=$1
	versoionName=$2
	sed -i -re "s/(versionName +\")[^\"]+\"/\1${versionName}\"/g" ${basedir}/rounds/build.gradle
	if ! egrep "versionName +\"${versionName}\"" rounds/build.gradle ;
    then
	    echo "could not find the right version name in the ${basedir}/rounds/build.gradle." >&2
    	echo "please check then commit and push the branch." >&2
    	exit 1
	fi
}

#bump=increase by one
function bumpVersionCode(){
	basedir=$1
	buildGradleContent=$(cat  ${basedir}/rounds/build.gradle)
	#regex that will put the braces result into BASH_REMATCH array
	[[ $buildGradleContent =~ versionCode\ ([0-9]+) ]]
	versionCode=${BASH_REMATCH[1]}
	if [[ "$versionCode" != "" ]] ;
	then
		versionCodeBumped=$((versionCode+1))
		sed -i -re "s/(versionCode +)[0-9]+/\1${versionCodeBumped}/g" ${basedir}/rounds/build.gradle
		if ! egrep "versionCode +${versionCodeBumped}" rounds/build.gradle ;
		then
			echo "could not find the right verison code in the ${basedir}/rounds/build.gradle." >&2
	    	echo "please check then commit and push the branch." >&2
	    	exit 1
		fi
	else
		echo "could not find versionCode in build.gradle you need on increase the version yourself!" >&2
		exit 2
	fi
}

#make sure the param is just a version name: x.y.zzz
function validateParam(){
	if ! [[ $1 =~ [1-9]\.[0-9]\.[0-9]+ ]];
	then
		echo "bad param given : $1 should be x.y.zzz" >&2
		exit 3
	fi	
}

if [[ $# -lt 1 ]] ;
then
    showHelp $0
else
	#first do validations
	validateParam $1
	validateCleanGitOrExit
	validateOnDevelopBranchOrExit
	#create base params - base dir for reference based on the script dir
	#and version name
	scriptsDir=$(dirname $(python -c 'import sys,os; os.path.realpath(sys.argv[1])' ${BASH_SOURCE[0]}))
	baseDir=$(python -c 'import sys,os; os.path.realpath(sys.argv[1])' ${scriptsDir}/../)
	versionName=$1
	echo will use versionName=${versionName}
	#define the branch name and tag name to mark the base of the branch
	branchName=release-${versionName}
	baseTagName=${branchName}_base
	#now prepare the branch
	git checkout -b $branchName 
    changeVersionName $baseDir $versionName
	bumpVersionCode $baseDir
	#if we are here all is ok otherwise the function will exit with error code
	#do the commits as 'one operation' and each operation should be done only if the previous one
	#was a success
	git commit -a -m "new release branch: ${branchName}" && \
	git push --set-upstream origin ${branchName} && \
	git tag $baseTagName && \
	git push origin $baseTagName
fi
