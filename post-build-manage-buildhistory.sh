#!/bin/bash

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>

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

if [ ! -z "$buildhistory_dir" ] && [ -d $buildhistory_dir ]; then
    rm -rf _buildhistory
    git clone $tree -b $branch _buildhistory
    cp -a $buildhistory_dir/* _buildhistory/
    cd _buildhistory
    git add -A
    git commit --allow-empty -m "Build : ${BUILD_NUMBER}"
    git push origin HEAD:$branch
else
    echo "Build history not found"
fi

