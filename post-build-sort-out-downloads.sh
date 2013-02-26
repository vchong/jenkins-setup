#!/bin/bash

mkdir -p ${WORKSPACE}/downloads

pushd ${WORKSPACE}/downloads
cp /mnt/ci_build/workspace/downloads/* .
rm *.done

# remove all sources which were already pushed
wget http://snapshots.linaro.org/openembedded/sources

for src in `grep 'alt="other"' sources |sed -e 's+.*">\(.*\)</a.*+\1+g'`
do
	rm $src
done

popd
