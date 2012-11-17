#!/bin/bash

# we need to sort it out
mkdir -p ${WORKSPACE}/downloads
cp /mnt/ci_build/workspace/downloads/* ${WORKSPACE}/downloads
rm ${WORKSPACE}/downloads/*.done

