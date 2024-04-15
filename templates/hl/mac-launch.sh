#!/usr/bin/env sh
# HashLink needs a specific working directory to find hlboot.dat and libraries
# automatically, so we use this script to configure them all manually
BASEDIR=$(dirname $0)
DYLD_LIBRARY_PATH=$BASEDIR:$DYLD_LIBRARY_PATH exec $BASEDIR/hl $BASEDIR/hlboot.dat "$@"