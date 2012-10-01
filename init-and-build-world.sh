#!/bin/bash

DIR=$(cd $(dirname "$0"); pwd)

source $DIR/init.sh

# do build

bitbake world -k

prepare_for_publish
