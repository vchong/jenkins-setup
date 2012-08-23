#!/bin/bash

DIR=$(cd $(dirname "$0"); pwd)

source $DIR/init.sh

# do build

bitbake -cfetchall linaro-image-sdk linaro-image-lamp

prepare_for_publish
