#!/bin/bash

# set some defaults
release=13.06
arch=armv8
gcc=4.8
external_url=
manifest_branch=${manifest_branch:-master}
manifest_repository=${manifest_repository:-git://git.linaro.org/openembedded/manifest.git}
manifest_groups=
bitbake_verbose=

export PATH=$PATH:$HOME/bin

source $(dirname $0)/functions.sh

while getopts “ha:b:m:r:g:u:i:v” OPTION
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
			manifest_branch=$OPTARG
			;;
		m)
			manifest_groups="-g $OPTARG"
			;;
		r)
			manifest_repository=$OPTARG
			;;
		g)
			gcc=$OPTARG
			;;
		u)
			external_url=$OPTARG
			;;
		i)
			init_env="$OPTARG"
			;;
		v)
			bitbake_verbose="-v"
			;;
	esac
done

shift $(( OPTIND-1 ))

if [ -n "${WORKSPACE}" ]; then
    WORKBASE=/mnt/ci_build/workspace
fi

show_setup

git_clone_update

if [ -z "$init_env" ]; then
    init_env
else
    eval $init_env
fi

bitbake $bitbake_verbose $@
