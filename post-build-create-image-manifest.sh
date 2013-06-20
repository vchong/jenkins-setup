#!/bin/bash

if [ -n "${WORKSPACE}" ]; then
	test -d ${WORKSPACE}/out || mkdir -p ${WORKSPACE}/out
	rm -rf ${WORKSPACE}/out/*
	deploy_dir=`find build -type d -name deploy`
	cd ${deploy_dir}/images
	for img in *.rootfs.tar.gz
	do
		if ! [ -h $img ] ; then
			img=`basename $img .rootfs.tar.gz`
			cp -a ../licenses/$img/license.manifest $img.manifest
			mv $img.* ${WORKSPACE}/out
		fi
	done
fi
