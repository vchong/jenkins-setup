#!/bin/bash

# provide manifest for images
branch=${1:-master}
cd $branch/build/tmp-eglibc/deploy/images/
for img in *.tar.gz
do
	if ! [ -h $img ] ; then
		img=`basename $img .rootfs.tar.gz`
		cp ../licenses/$img/license.manifest $img.manifest
	fi
done
