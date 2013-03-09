#!/bin/bash

rm -rf ${WORKSPACE}/downloads
mkdir -p ${WORKSPACE}/downloads

pushd ${WORKSPACE}/downloads
cp /mnt/ci_build/workspace/downloads/* .
rm *.done

# remove all sources which were already pushed
wget http://snapshots.linaro.org/openembedded/sources

for src in ` grep 'a href="/openem' sources |sed -e 's+.*sources\/\(.*\)"+\1+g' | egrep -v ^git2_git.linaro.*linux`
do
	rm -f $src
done

popd
