#!/bin/bash

set -e

# only run on Jenkins
if [ -z "${WORKSPACE}" ]; then
    exit 1
fi

usage()
{
    cat << EOF
usage: $0 options

This script should be run at the end of a Linaro OpenEmbedded build,
to archive a copy of the buildhistory artifacts

OPTIONS:
   -h      Show this message
   -r      Repository where artifacts will be pushed
   -b      Git Branch to use
   -v      Verbose output
EOF
}


while getopts “hb:r:v” OPTION
do
	case $OPTION in
		h)
			usage
			exit
			;;
		r)
			tree=$OPTARG
			;;
		b)
			branch=$OPTARG
			;;
		v)
			set -x
			;;
	esac
done

if [ -z "$tree" ] || [ -z "$branch" ] ; then
    usage
    exit 1
fi

buildhistory_dir=`find build -maxdepth 2 -type d -name buildhistory`
if [ ! -d $buildhistory_dir ]; then
	buildhistory_dir=`find /mnt/ci_build/workspace/tmp -type d -name buildhistory`
fi

buildstats_dir=`find build -maxdepth 2 -type d -name buildstats`
if [ ! -d $buildstats_dir ]; then
	buildstats_dir=`find /mnt/ci_build/workspace/tmp -type d -name buildstats`
fi

if [ ! -z "$buildhistory_dir" ] && [ -d $buildhistory_dir ]; then
    rm -rf _buildhistory
    git clone $tree -b $branch _buildhistory
    cp -a $buildhistory_dir/* _buildhistory/

    # also copy buildstats if they exist
    if [ ! -z "$buildstats_dir" ] && [ -d $buildstats_dir ]; then
        mkdir -p _buildhistory/buildstats
        # buildstats has this layout:
        #  buildstats/<build-name>-<machine>/<timestamp>/<recipe-PF>/stats
        # we want to copy only the leaf folders with the stats, otherwise the commit diff
        # will be hard to read (if it includes the timestamps which changes everyday)
        find $buildstats_dir/*/*/* -type d | xargs -i cp -a {} _buildhistory/buildstats/
    fi

    cd _buildhistory
    git add -A
    git commit --allow-empty -m "${DATE}-${BUILD_NUMBER}"
    git push origin HEAD:$branch
else
    echo "Build history not found"
fi

