#!/bin/bash

if [ -n "${WORKSPACE}" ]; then
	test -d ${WORKSPACE}/out || mkdir -p ${WORKSPACE}/out
	rm -rf ${WORKSPACE}/out/*
	oe_init_build_env=`find . -maxdepth 2 -type f -name oe-init-build-env`
	source ${oe_init_build_env} build
	deploy_dir_image=`bitbake -e | grep "^DEPLOY_DIR_IMAGE="| cut -d'=' -f2 | tr -d '"'`
	license_directory=`bitbake -e | grep "^LICENSE_DIRECTORY="| cut -d'=' -f2 | tr -d '"'`
	license_manifest=`find ${license_directory} -type f -name 'license.manifest'`
	image_name=`dirname ${license_manifest}`
	image_name=`basename ${image_name}`
	cp -a ${license_manifest} ${WORKSPACE}/out/${image_name}.manifest
	mv ${deploy_dir_image}/${image_name}.* ${WORKSPACE}/out
fi
