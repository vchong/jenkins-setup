#!/bin/bash

# we need to sort it out
mkdir -p ${WORKSPACE}/downloads
cp /mnt/ci_build/workspace/downloads/* ${WORKSPACE}/downloads
rm ${WORKSPACE}/downloads/*.done

# provide manifest for images
cd build/tmp-eglibc/deploy/images/
for img in *.ext2.gz
do
	img=`basename $img .rootfs.ext2.gz`
	cp ../licenses/$img/license.manifest $img.manifest
done
