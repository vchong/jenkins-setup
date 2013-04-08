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

# to save space we remove source after build
INHERIT += "rm_work"

MACHINE = "generic${arch}"

# those numbers can be tweaked if build takes too much power
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j8"

# add 'ext2' if you want images for fast models
IMAGE_FSTYPES = "tar.gz"
IMAGE_LINGUAS = "en-gb"

GCCVERSION       ?= "linaro-${gcc}"
SDKGCCVERSION    ?= "linaro-${gcc}"

# we need libevent-fb for hiphopvm
PREFERRED_PROVIDER_libevent = "libevent-fb"

# enable source mirror
SOURCE_MIRROR_URL = "http://snapshots.linaro.org/openembedded/sources/"
INHERIT += "own-mirrors"
EOF

# enable sstate mirror

# disabled for now - we do not have it yet
#echo 'SSTATE_MIRRORS = "file://.* http://snapshots.linaro.org/openembedded/sstate-cache/"' >>conf/site.conf

# enable a distro feature that is compatible with the minimal goal we have
echo 'DISTRO_FEATURES = "x11 alsa argp ext2 largefile usbgadget usbhost xattr nfs zeroconf ${DISTRO_FEATURES_LIBC} ${DISTRO_FEATURES_INITMAN}"' >>conf/site.conf

if [ -n "${WORKSPACE}" ]; then
    # share downloads and sstate-cache between all builds
    echo 'DL_DIR = "/mnt/ci_build/workspace/downloads"' >>conf/site.conf
    echo 'SSTATE_DIR = "/mnt/ci_build/workspace/sstate-cache"' >>conf/site.conf
    echo 'BB_GENERATE_MIRROR_TARBALLS = "True"' >>conf/site.conf

    # LP: #1161808
    echo "IMAGE_NAME = \"\${IMAGE_BASENAME}-\${MACHINE}-\${DATE}-${BUILD_NUMBER}\"" >>conf/site.conf
fi

# get rid of MACHINE setting from local.conf

sed -i -e "s/^MACHINE.*//g" conf/local.conf

if [ 1 -eq `date +%w` ]; then
	../openembedded-core/scripts/sstate-cache-management.sh --yes --remove-duplicated \
		--extra-layer ../meta-linaro/meta-aarch64,../meta-linaro/meta-linaro,\
		../meta-linaro/meta-linaro-toolchain,../meta-openembedded/meta-oe,\
		../meta-openembedded/toolchain-layers,../meta-openembedded/meta-webserver \
		--cache-dir=/mnt/ci_build/workspace/sstate-cache
fi

if [ -n "$1" ];
then
	bitbake $1
fi
