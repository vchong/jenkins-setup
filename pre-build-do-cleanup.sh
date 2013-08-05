#!/bin/bash

if [ -n "${WORKSPACE}" ]; then
    # clean builds from all jobs to get disk space back
    find ${WORKSPACE} -type d -name build | xargs rm -rf

    # clean shared tmpdir
    rm -rf /mnt/ci_build/workspace/tmp-eglibc || true

    # those should not exist but they may
    find ${WORKSPACE} -type d -name downloads | xargs rm -rf

    # || true as some of those dirs may not exist
    du -hs ${WORKSPACE} \
       /mnt/ci_build/workspace/downloads \
       /mnt/ci_build/workspace/sstate-cache || true
    df -h
fi
