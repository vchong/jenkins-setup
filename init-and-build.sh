#!/bin/bash

arch=armv8
gcc=4.7

if [ ! -z $2 ];
then
	arch=$2
fi

if [ ! -z $3 ];
then
	gcc=$3
fi

# clone/update repositories

# old checkout of meta-linaro
if [ ! -d meta-linaro/conf ]; then
	git clone git://git.linaro.org/openembedded/meta-linaro.git
else
	pushd meta-linaro;git pull;popd
fi

# new checkout of meta-linaro
if [ ! -d meta-linaro/meta-linaro/conf ]; then
	git clone git://git.linaro.org/openembedded/meta-linaro.git
else
	pushd meta-linaro;git pull;popd
fi
if [ ! -d meta-openembedded/meta-oe ]; then
	git clone git://git.openembedded.org/meta-openembedded
else
	pushd meta-openembedded;git pull;popd
fi
if [ ! -d openembedded-core/meta ]; then
	git clone git://git.openembedded.org/openembedded-core
else
	pushd openembedded-core;git pull;popd
fi

# 13.03 release freeze

# pushd meta-linaro
# git checkout 9ba698baa24d78b9400292c7738ad34edaf63e05
# popd

# pushd meta-openembedded
# git checkout 6cbd81ed18465affba841311ec1cdf3eb6800dba
# popd

# pushd openembedded-core
# git checkout d9130e5113c8f93f327fbe19dbfe39036c1c3995
# popd

# pushd openembedded-core/bitbake
# git checkout 2ecb102968cdbbdbbfa91e1dcccf45bcd0b59a89
# popd

cd openembedded-core/

if [ ! -d bitbake/conf ]; then
	git clone git://git.openembedded.org/bitbake
else
	pushd bitbake;git pull;popd
fi

# let's start build
. oe-init-build-env ../build

# add required layers

echo "BBLAYERS = '`realpath $PWD/../meta-openembedded/meta-oe`'" >>conf/bblayers.conf 
echo "BBLAYERS += '`realpath $PWD/../meta-openembedded/meta-webserver`'" >>conf/bblayers.conf
echo "BBLAYERS += '`realpath $PWD/../meta-openembedded/toolchain-layer`'" >>conf/bblayers.conf 
echo "BBLAYERS += '`realpath $PWD/../meta-linaro/meta-aarch64`'" >>conf/bblayers.conf
echo "BBLAYERS += '`realpath $PWD/../meta-linaro/meta-linaro`'" >>conf/bblayers.conf
echo "BBLAYERS += '`realpath $PWD/../meta-linaro/meta-linaro-toolchain`'" >>conf/bblayers.conf
echo "BBLAYERS += '`realpath $PWD/../openembedded-core/meta`'" >>conf/bblayers.conf 

# Add some Linaro related options

echo 'SCONF_VERSION = "1"'					 			>conf/site.conf
echo '# specify the alignment of the root file system' 	>>conf/site.conf
echo '# this is required when building for qemuarmv7a' 	>>conf/site.conf
echo 'IMAGE_ROOTFS_ALIGNMENT = "2048"' 					>>conf/site.conf
echo 'INHERIT += "rm_work"' 							>>conf/site.conf
echo 'BB_GENERATE_MIRROR_TARBALLS = "True"' 			>>conf/site.conf
echo "MACHINE = \"generic${arch}\""						>>conf/site.conf
echo 'BB_NUMBER_THREADS = "8"'							>>conf/site.conf
echo 'PARALLEL_MAKE = "-j8"'							>>conf/site.conf
echo 'IMAGE_FSTYPES = "tar.gz"'					>>conf/site.conf
echo 'IMAGE_LINGUAS = "en-gb"'					>>conf/site.conf
echo "GCCVERSION       ?= \"linaro-${gcc}\""					>>conf/site.conf
echo "SDKGCCVERSION    ?= \"linaro-${gcc}\""					>>conf/site.conf

# set some preferred providers
#  we need libevent-fb for hiphopvm
echo 'PREFERRED_PROVIDER_libevent = "libevent-fb"' >>conf/site.conf

if [ -n "${WORKSPACE}" ]; then
    # share downloads and sstate-cache between all builds
    echo 'DL_DIR = "/mnt/ci_build/workspace/downloads"' >>conf/site.conf
    echo 'SSTATE_DIR = "/mnt/ci_build/workspace/sstate-cache"' >>conf/site.conf

    # LP: #1161808
    echo 'IMAGE_NAME = "${IMAGE_BASENAME}-${MACHINE}-${DATE}-${BUILD_NUMBER}"' >>conf/site.conf
fi

# enable source mirror

echo 'SOURCE_MIRROR_URL = "http://snapshots.linaro.org/openembedded/sources/"' >>conf/site.conf
echo 'INHERIT += "own-mirrors"' 								>>conf/site.conf

# enable sstate mirror

# disabled for now - we do not have it yet
#echo 'SSTATE_MIRRORS = "file://.* http://snapshots.linaro.org/openembedded/sstate-cache/"' >>conf/site.conf

# enable a distro feature that is compatible with the minimal goal we have

echo 'DISTRO_FEATURES = "x11 alsa argp ext2 largefile usbgadget usbhost xattr nfs zeroconf ${DISTRO_FEATURES_LIBC} ${DISTRO_FEATURES_INITMAN}"' >>conf/site.conf

# get rid of MACHINE setting from local.conf

sed -i -e "s/^MACHINE.*//g" conf/local.conf

if [ -n "$1" ];
then
	bitbake $1
fi
