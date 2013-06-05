#!/bin/bash -e

# set some defaults

# periodic maintainence for OE builders

job=soft

source functions.sh
WORKBASE=/mnt/ci_build/workspace

while getopts “w:x:” OPTION
do
	case $OPTION in
		x)
			job=$OPTARG
			;;
        w)
            WORKBASE=$OPTARG
	esac
done

shift $(( OPTIND-1 ))

cd openembedded-core
. oe-init-build-env ../build

case $job in
    soft)
        cleanup_soft
        ;;
    hard)
        cleanup_hard
        ;;
esac
