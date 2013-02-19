#!/bin/bash

if [ "$(basename $PWD)" != "deploy" ]; then
    echo "Must be in deploy directory"
    exit 1
fi

set -x

CURRENT_OMERO=$1
NEW_OMERO=$2

[ -z "$CURRENT_OMERO" ] && echo "Missing Current Omero dir" && exit 1
[ -z "$NEW_OMERO" ] && echo "Missing New Omero dir" && exit 1
##[ ! -d "$CURRENT_OMERO" ] && echo "$CURRENT_OMERO is not a directory" && exit 1
[ ! -d "$NEW_OMERO" ] && echo "$NEW_OMERO is not a directory" && exit 1 

if [ -d "$CURRENT_OMERO" ]; then
    pushd $CURRENT_OMERO
    CURRENT_PID=$( bin/omero web status | awk '{ print $5 }' |sed -e 's/)//' )
    popd
fi

# these must match whatever is configured in nginx
AVAILABLE_PORTS="9090 9091"
START_PORT=''

for port in $AVAILABLE_PORTS; do
    nc -z -n 127.0.0.1 $port &> /dev/null
    if [ "$?" -eq 0 ]; then
        # port in use
        true
    else
        # port free
        START_PORT=$port
    fi
done

[ -z "$START_PORT" ] && echo "No available ports... aborting!" && exit 1

pushd $NEW_OMERO
# set port to start omero.web on
bin/omero config set omero.web.application_server.port $START_PORT
# start new omero.web
bin/omero web start
popd

# send a HUP to the top django process to force a graceful shutdown of the workers
if [ -n "$CURRENT_PID" ]; then
    kill -HUP $CURRENT_PID
fi

# readjust symlinks
ln -T -s -vf $NEW_OMERO ./current
