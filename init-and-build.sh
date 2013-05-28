#!/bin/bash

# set some defaults
release=13.04
arch=armv8
gcc=4.7
external_url=
jenkins=

source functions.sh

while getopts “ha:g:u:” OPTION
do
	case $OPTION in
		h)
			usage
			exit
			;;
		a)
			arch=$OPTARG
			;;
		g)
			gcc=$OPTARG
			;;
		u)
			external_url=$OPTARG
			;;
	esac
done

shift $(( OPTIND-1 ))

if [ -n "${WORKSPACE}" ]; then
	jenkins=1
fi

show_setup

git_clone_update
# git_freeze

# let's start build
. oe-init-build-env ../build

conf_bblayers
conf_siteconf
conf_localconf
conf_toolchain
conf_jenkins

# workaround for LP: #1183087
if [ $jenkins ]; then
	if [ `echo "$@" | grep lamp` ];then
		bitbake -ccleansstate libunwind
		bitbake gcc
	fi
fi

bitbake $@
