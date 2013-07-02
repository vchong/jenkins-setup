#!/bin/bash

unset sync

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

git_clone_update()
{

   if [ -n "${WORKSPACE}" ]; then
        if [ ! -d .repo ]; then
            echo "jenkins repo init"
            repo init  -u $manifest_repository -b $manifest_branch -m default.xml --repo-url=git://android.git.linaro.org/tools/repo
        fi
        echo "jenkins repo sync"
        repo sync -j4
    # FIXME: check if the following code is really needed
    elif [[ -d .repo ]]; then
        echo "rebase"
        for project in $(cat .repo/project.list); do
            if [[ ! -d $project ]]; then
                sync=1
            fi
        done
        if [[ $sync = 1 ]]; then
            repo sync
        fi
       repo rebase
    else
        repo init --quiet -u $manifest_repository -b $manifest_branch -m default.xml --repo-url=git://android.git.linaro.org/tools/repo
        time repo sync --quiet -j3
    fi
}

git_freeze()
{
# release freeze

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
EOF
if [[ -d ../poky ]]; then
    echo "BBLAYERS += '`realpath $PWD/../poky/meta`'">>conf/bblayers.conf
    echo "BBLAYERS += '`realpath $PWD/../poky/meta-yocto`'">>conf/bblayers.conf
else
    echo "BBLAYERS += '`realpath $PWD/../openembedded-core/meta`'">>conf/bblayers.conf
fi
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

if [[ -d ../poky ]]; then
    cat >> conf/site.conf <<EOF

# ipk a debian style embedded package manager.
PACKAGE_CLASSES = "package_ipk"

# Need this for the netperf package.
LICENSE_FLAGS_WHITELIST = "non-commercial"

EOF
fi

# enable a distro feature that is compatible with the minimal goal we have
echo 'DISTRO_FEATURES = "x11 alsa argp ext2 largefile usbgadget usbhost xattr nfs zeroconf ${DISTRO_FEATURES_LIBC} ${DISTRO_FEATURES_INITMAN}"' >>conf/site.conf
}

conf_toolchain()
{
    if [ $external_url ];then
        echo 'TCMODE = "external-linaro"' >>conf/site.conf
        tarball_name=`echo $external_url | cut -d "/" -f 8`
        mkdir -p toolchain

        if [ -n "${WORKSPACE}" ]; then
            local_tarball_name=${WORKBASE}/downloads/$tarball_name
        else
            local_tarball_name=toolchain/$tarball_name
        fi

        if [ ! -e $local_tarball_name ];then
            wget -cq $external_url -O $local_tarball_name
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
   -b      manifest branch
   -g      GCC version (4.7 or 4.8)
   -u      External Linaro toolchain URL
EOF
}
