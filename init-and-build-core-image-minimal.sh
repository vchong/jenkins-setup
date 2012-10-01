#!/bin/bash

DIR=$(cd $(dirname "$0"); pwd)

source $DIR/init.sh

# do build

bitbake core-image-minimal

prepare_for_publish
