#!/bin/bash

# set some defaults
release=13.04
arch=armv8
gcc=4.8
external_url=
jenkins=
branch=master
repository=${repository:-git://git.linaro.org/openembedded/manifest.git}

source functions.sh

while getopts “ha:b:g:u:” OPTION
do
	case $OPTION in
		h)
			usage
			exit
			;;
		a)
			arch=$OPTARG
			;;
		b)
			branch=$OPTARG
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
    WORKBASE=/mnt/ci_build/workspace
fi

show_setup

git_clone_update

if [[ -d openembedded-core ]]; then
    cd openembedded-core
else
    cd poky
fi
# set up OE enviroment variables
. oe-init-build-env ../build

conf_bblayers
conf_siteconf
conf_localconf
conf_toolchain
conf_jenkins
cleanup_soft

bitbake $@
