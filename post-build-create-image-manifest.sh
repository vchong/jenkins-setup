#!/bin/bash

usage()
{
    cat << EOF
usage: $0 options

This script should be run at the end of a Linaro OpenEmbedded build,
to prepare the 'output' folder

OPTIONS:
   -h      Show this message
   -v      Verbose output
EOF
}


while getopts “hv” OPTION
do
	case $OPTION in
		h)
			usage
			exit
			;;
		v)
			set -x
			;;
	esac
done

if [ -n "${WORKSPACE}" ]; then
	test -d ${WORKSPACE}/out || mkdir -p ${WORKSPACE}/out
	rm -rf ${WORKSPACE}/out/*
	oe_init_build_env=`find . -maxdepth 2 -type f -name oe-init-build-env`
	source ${oe_init_build_env} build
	deploy_dir_image=`bitbake -e | grep "^DEPLOY_DIR_IMAGE="| cut -d'=' -f2 | tr -d '"'`
	license_directory=`bitbake -e | grep "^LICENSE_DIRECTORY="| cut -d'=' -f2 | tr -d '"'`
	license_manifests=`find ${license_directory} -type f -name 'license.manifest'`
	for manifest in ${license_manifests}
	do
		image_name=`dirname ${manifest}`
		image_name=`basename ${image_name}`
		cp -a ${manifest} ${WORKSPACE}/out/${image_name}.manifest
		mv ${deploy_dir_image}/${image_name}.* ${WORKSPACE}/out
	done
fi
