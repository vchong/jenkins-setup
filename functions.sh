#!/bin/bash


show_setup()
{
    echo ""
    echo "GCC version: $gcc"
    echo "Target architecture: $arch"

    if [ $external_url ]; then
        echo "External toolchain URL: $external_url"
    fi
    echo ""
}

git_pull()
{
    pushd $1 >/dev/null
    git pull
    popd >/dev/null
}

git_clone_update()
{
# clone/update repositories

if [ ! -d meta-linaro/meta-linaro/conf ]; then
    # old checkout of meta-linaro
    if [ -d meta-linaro/conf ]; then
        git_pull meta-linaro
    else
        git clone git://git.linaro.org/openembedded/meta-linaro.git
    fi
else
    git_pull meta-linaro
fi
if [ ! -d meta-openembedded/meta-oe ]; then
    git clone git://git.openembedded.org/meta-openembedded
else
    git_pull meta-openembedded
fi
if [ ! -d openembedded-core/meta ]; then
    git clone git://git.openembedded.org/openembedded-core
else
    git_pull openembedded-core
fi

# add meta-java for Andy Johnson
if [ ! -d meta-java/conf ]; then
    git clone git://github.com/woglinde/meta-java.git
else
    git_pull meta-java
fi

cd openembedded-core/

if [ ! -d bitbake/conf ]; then
    git clone git://git.openembedded.org/bitbake
else
    git_pull bitbake
fi

}

git_freeze()
{
# 13.03 release freeze

pushd meta-linaro
git checkout 9ba698baa24d78b9400292c7738ad34edaf63e05
popd

pushd meta-openembedded
git checkout 6cbd81ed18465affba841311ec1cdf3eb6800dba
popd

pushd openembedded-core
git checkout d9130e5113c8f93f327fbe19dbfe39036c1c3995
popd

pushd openembedded-core/bitbake
git checkout 2ecb102968cdbbdbbfa91e1dcccf45bcd0b59a89
popd

}

conf_bblayers()
{
# add required layers

cat >> conf/bblayers.conf <<EOF
BBLAYERS  = '`realpath $PWD/../meta-openembedded/meta-oe`'
BBLAYERS += '`realpath $PWD/../meta-openembedded/meta-webserver`'
BBLAYERS += '`realpath $PWD/../meta-openembedded/meta-networking`'
BBLAYERS += '`realpath $PWD/../meta-openembedded/toolchain-layer`'
BBLAYERS += '`realpath $PWD/../meta-linaro/meta-aarch64`'
BBLAYERS += '`realpath $PWD/../meta-linaro/meta-linaro`'
BBLAYERS += '`realpath $PWD/../meta-linaro/meta-linaro-toolchain`'
BBLAYERS += '`realpath $PWD/../meta-java`'
BBLAYERS += '`realpath $PWD/../openembedded-core/meta`'
EOF

}

conf_siteconf()
{
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
BINUVERSION      ?= "2.23.2"

# some options needed for HipHopVM
PREFERRED_PROVIDER_libevent = "libevent-fb"
PREFERRED_VERSION_libmemcached = "1.0.7"

# some options for Andy's work on OpenJDK for AArch64
PREFERRED_PROVIDER_virtual/java-native = "jamvm-native"
PREFERRED_PROVIDER_virtual/javac-native = "ecj-bootstrap-native"
PREFERRED_VERSION_openjdk-7-jre = "03b21-2.1.8"
PREFERRED_VERSION_icedtea7-native = "2.1.3"


# enable source mirror
SOURCE_MIRROR_URL = "http://snapshots.linaro.org/openembedded/sources/"
INHERIT += "own-mirrors"
EOF

# enable a distro feature that is compatible with the minimal goal we have
echo 'DISTRO_FEATURES = "x11 alsa argp ext2 largefile usbgadget usbhost xattr nfs zeroconf ${DISTRO_FEATURES_LIBC} ${DISTRO_FEATURES_INITMAN}"' >>conf/site.conf
}

conf_toolchain()
{
    if [ $external_url ];then
        echo 'TCMODE = "external-linaro"' >>conf/site.conf
        tarball_name=`echo $external_url | cut -d "/" -f 8`
        mkdir -p toolchain

        if [ $jenkins ]; then
            local_tarball_name=/mnt/ci_build/workspace/downloads/$tarball_name
        else
            local_tarball_name=toolchain/$tarball_name
        fi

        if [ ! -e $local_tarball_name ];then
            wget -c $external_url -O $local_tarball_name
        fi
        tar xf $local_tarball_name -C toolchain

        echo "EXTERNAL_TOOLCHAIN = \"`pwd`/toolchain/`echo $tarball_name|sed -e 's/\(.*\)\.tar..*/\1/g'`\"" >> conf/site.conf

        case $arch in
            armv7a)
                echo 'ELT_TARGET_SYS = "arm-linux-gnueabihf"' >>conf/site.conf
                ;;
            armv8)
                echo 'ELT_TARGET_SYS = "aarch64-linux-gnu"' >>conf/site.conf
                ;;
        esac

    fi
}

conf_jenkins()
{
    if [ -n "${WORKSPACE}" ]; then
        # share downloads and sstate-cache between all builds
        echo 'DL_DIR = "/mnt/ci_build/workspace/downloads"' >>conf/site.conf
        echo 'SSTATE_DIR = "/mnt/ci_build/workspace/sstate-cache"' >>conf/site.conf
        echo 'BB_GENERATE_MIRROR_TARBALLS = "True"' >>conf/site.conf

        # LP: #1161808
        echo "IMAGE_NAME = \"\${IMAGE_BASENAME}-\${MACHINE}-\${DATE}-${BUILD_NUMBER}\"" >>conf/site.conf
    fi
}

conf_localconf()
{
    # get rid of MACHINE setting from local.conf

    sed -i -e "s/^MACHINE.*//g" conf/local.conf
}

cleanup_soft()
{
    if [ -n "${WORKBASE}" ]; then
        echo "soft cleanup at ${WORKBASE}"
        df -h ${WORKBASE}
        ../openembedded-core/scripts/sstate-cache-management.sh --yes --remove-duplicated \
                --extra-layer=../meta-linaro/meta-aarch64,../meta-linaro/meta-linaro,../meta-linaro/meta-linaro-toolchain,../meta-openembedded/meta-oe,../meta-openembedded/toolchain-layer,../meta-openembedded/meta-webserver \
                --cache-dir=${WORKBASE}/sstate-cache
        df -h ${WORKBASE}
        ../openembedded-core/scripts/cleanup-workdir
        df -h ${WORKBASE}
    fi
}

cleanup_hard()
{
    if [ -n "${WORKBASE}" ]; then
        echo "hard cleanup at ${WORKBASE}"
        df -h ${WORKBASE}
        rm -rf ${WORKBASE}/sstate-cache
        #rm -rf ${WORKBASE}/downloads
        df -h ${WORKBASE}
    fi
}

usage()
{
    cat << EOF
usage: $0 options

This script initialize and run OpenEmbedded builds with Linaro settings.

OPTIONS:
   -h      Show this message
   -a      Target architecture (armv7a or armv8)
   -g      GCC version (4.7 or 4.8)
   -u      External Linaro toolchain URL
EOF
}
