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

cd openembedded-core/

if [ ! -d bitbake/conf ]; then
	git clone git://git.openembedded.org/bitbake
else
	pushd bitbake;git pull;popd
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

# let's start build
. oe-init-build-env ../build

# add required layers

cat >> conf/bblayers.conf <<EOF
BBLAYERS = '`realpath $PWD/../meta-openembedded/meta-oe`'
BBLAYERS += '`realpath $PWD/../meta-openembedded/meta-webserver`'
BBLAYERS += '`realpath $PWD/../meta-openembedded/toolchain-layer`'
BBLAYERS += '`realpath $PWD/../meta-linaro/meta-aarch64`'
BBLAYERS += '`realpath $PWD/../meta-linaro/meta-linaro`'
BBLAYERS += '`realpath $PWD/../meta-linaro/meta-linaro-toolchain`'
BBLAYERS += '`realpath $PWD/../openembedded-core/meta`'
EOF

# Add some Linaro related options

cat > conf/site.conf <<EOF
SCONF_VERSION = "1"
# specify the alignment of the root file system
# this is required when building for qemuarmv7a
IMAGE_ROOTFS_ALIGNMENT = "2048"
INHERIT += "rm_work"
BB_GENERATE_MIRROR_TARBALLS = "True"
MACHINE = "generic${arch}"
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j8"
IMAGE_FSTYPES = "tar.gz"
IMAGE_LINGUAS = "en-gb"
GCCVERSION       ?= "linaro-${gcc}"
SDKGCCVERSION    ?= "linaro-${gcc}"
EOF

# set some preferred providers
#  we need libevent-fb for hiphopvm
echo 'PREFERRED_PROVIDER_libevent = "libevent-fb"' >>conf/site.conf

if [ -n "${WORKSPACE}" ]; then
    # share downloads and sstate-cache between all builds
    echo 'DL_DIR = "/mnt/ci_build/workspace/downloads"' >>conf/site.conf
    echo 'SSTATE_DIR = "/mnt/ci_build/workspace/sstate-cache"' >>conf/site.conf

    # LP: #1161808
    echo "IMAGE_NAME = \"\${IMAGE_BASENAME}-\${MACHINE}-\${DATE}-${BUILD_NUMBER}\"" >>conf/site.conf
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
