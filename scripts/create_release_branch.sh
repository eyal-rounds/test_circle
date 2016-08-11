#!/bin/bash -x

APP_DIR="app"

function show_error(){
	echo -e "\e[91m$1\e[97m" >&2
	exit $2
}
	
function showHelp(){
	echo -e "help: command construct is \n$0 [version name]"
	echo "example: $1 5.3.1"
}

function validateCleanGitOrExit(){
	local isClean
	git status|grep -c "nothing to commit" >/dev/null 2>&1
	if [[ $? -ne 0 ]] ;
	then
		show_error "workspace is not clean! we need clean slate to create a release branch" 1
	fi
}

function validateOnDevelopBranchOrExit(){
	local branchName
	branchName=$(git name-rev --name-only HEAD)
	if [[ "${branchName}" != "develop" ]] ;
	then
		show_error "you MUST BE on develop branch to create a new release branch.\nplease do: % git checkout develop and re-run this script" 1
	fi
}

function changeVersionName(){
	gradleFile=$1
	versoionName=$2
    sed -i -e "s/\(versionName *\"\)[^\"][^\"]*\"/\1${versionName}\"/g" ${gradleFile}
    sleep 1
	if ! egrep "versionName +\"${versionName}\"" ${gradleFile} ;
	then
		show_error "could not find the right version name in the ${gradleFile}.\nplease check then commit and push the branch." 1
	fi
}

#bump=increase by one
function bumpVersionCode(){
	gradleFile=$1
	local buildGradleContent
	buildGradleContent=$(cat  $gradleFile)
	#regex that will put the braces result into BASH_REMATCH array
	[[ $buildGradleContent =~ versionCode\ ([0-9]+) ]]
	versionCode=${BASH_REMATCH[1]}
	if [[ "$versionCode" != "" ]] ;
	then
		versionCodeBumped=$((versionCode+1))
		sed -i -e "s/\(versionCode  *\)[0-9][0-9]*/\1${versionCodeBumped}/g" ${gradleFile}
		if ! egrep "versionCode +${versionCodeBumped}" ${gradleFile} ;
		then
			show_error "could not find the right verison code in the ${gradleFile}.\nplease check then commit and push the branch." 1
		fi
	else
		show_error "could not find versionCode in build.gradle you need on increase the version yourself!" 2
	fi
}

#make sure the param is just a version name: x.y.zzz
function validateParam(){
	if ! [[ $1 =~ [1-9]\.[0-9]\.[0-9]+ ]];
	then
		show_error "bad param given : $1 should be x.y.zzz" 3
	fi	
}
validateBranch=0
validateClean=0
if [[ $# -gt 0 ]]
then
	params=()
	for i in "$@"
	do
		case $i in
			-b|--no-branch-validation)
			validateBranch=1
			;;
			-c|--no-clean-validation)
			validateClean=1
			;;
			*)
			params+=("$i")
			;;
		esac
	done
	set -- "${params[@]}"
fi

if [[ $# -lt 1 ]] ;
then
	showHelp $0
else
	#first do validations
	validateParam $1
	if [[ $validateClean -eq 0 ]];
	then
		validateCleanGitOrExit
	fi
	if [[ $validateBranch -eq 0 ]];
	then
		validateOnDevelopBranchOrExit
	fi
	#create base params - base dir for reference based on the script dir
	#and version name
	scriptsDir=$(dirname $(python -c 'import sys,os; print(os.path.realpath(sys.argv[1]))' ${BASH_SOURCE[0]}))
	baseDir=$(python -c 'import sys,os; print(os.path.realpath(sys.argv[1]))' ${scriptsDir}/../)
    gradleAppFile=${baseDir}/${APP_DIR}/build.gradle
	versionName=$1
	echo will use versionName=${versionName}
	#define the branch name and tag name to mark the base of the branch
	branchName=release-${versionName}
	baseTagName=${branchName}_base
	#now prepare the branch
	git checkout -b $branchName 
	changeVersionName $gradleAppFile $versionName
	bumpVersionCode $gradleAppFile
	#if we are here all is ok otherwise the function will exit with error code
	#do the commits as 'one operation' and each operation should be done only if the previous one
	#was a success
	git commit -a -m "new release branch: ${branchName}" && \
	git push --set-upstream origin ${branchName} && \
	git tag ${baseTagName} && \
	git push origin $baseTagName
fi
