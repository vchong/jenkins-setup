#!/bin/bash

# clean builds from all jobs to get disk space back
# path is something like that: openembedded-armv8-rootfs/label/oe_persistent_cloud/rootfs/lamp/
rm -rf /mnt/ci_build/workspace/openembedded-armv8-rootfs/label/*/*/*/build
rm -rf /mnt/ci_build/workspace/openembedded-armv7a-lamp/gcc_version/*/label/*/build

# those should not exist but they may
rm -rf /mnt/ci_build/workspace/openembedded-armv8-rootfs/label/*/*/*/downloads
rm -rf /mnt/ci_build/workspace/openembedded-armv7a-lamp/gcc_version/*/label/*/downloads

# || true as some of those dirs may not exist
du -hs /mnt/ci_build/workspace/openembedded-armv8-rootfs/label/ \
       /mnt/ci_build/workspace/openembedded-armv7a-lamp/gcc_version/ \
       /mnt/ci_build/workspace/downloads \
       /mnt/ci_build/workspace/sstate-cache || true
df -h
