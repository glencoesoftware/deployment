#!/bin/bash

set -x
set -e

[ -z "$1" ] && echo "Missing build number!" && exit 1

BUILD_NUMBER=$1

# get info for topdir from zip
VERSION_DIR=$( zipinfo -1 OMERO.py-*-b${BUILD_NUMBER}.zip |head -1 )

# unzip targets
# unzip omero.web
unzip -o OMERO.py-*-b$BUILD_NUMBER.zip

# copy configs into new build dir
cp -fvr config/* $VERSION_DIR/

# switch between running omero webs
./toggle-omeroweb.sh current $VERSION_DIR
