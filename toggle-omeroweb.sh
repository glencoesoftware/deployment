#!/bin/bash

LOCKFILE=deploy.lock

[ -f $LOCKFILE ] && exit 0

# Upon exit, remove lockfile.
trap "{ rm -f $LOCKFILE ; exit 0; }" EXIT SIGTERM SIGHUP
touch $LOCKFILE

set -x

CURRENT_OMERO=$1
NEW_OMERO=$2

[ -z "$CURRENT_OMERO" ] && echo "Missing Current Omero dir" && exit 1
[ -z "$NEW_OMERO" ] && echo "Missing New Omero dir" && exit 1
##[ ! -d "$CURRENT_OMERO" ] && echo "$CURRENT_OMERO is not a directory" && exit 1
[ ! -d "$NEW_OMERO" ] && echo "$NEW_OMERO is not a directory" && exit 1 

if [ -d "$CURRENT_OMERO" ]; then
    pushd $CURRENT_OMERO
    CURRENT_PID=$(< var/django.pid )
    ##CURRENT_PID=$( bin/omero web status | awk '{ print $5 }' |sed -e 's/)//' )
    popd
fi

# these must match whatever is configured in nginx
: ${AVAILABLE_PORTS:="9090 9091"}
START_PORT=''

for port in $AVAILABLE_PORTS; do
    nc -z -n 127.0.0.1 $port &> /dev/null
    RET=$?
    if [ "$RET" -eq 0 ]; then
        # port in use
        true
    elif [ "$RET" -eq 127 ]; then
        echo "Problem checking port -- ensure netcat is installed -- aborting!"
        exit 2
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
# there is a some latency between when django starts and can serve requests so we wait a bit to make sure it's up before stopping the old one
bin/omero web start && sleep 2s
# change upstream config
popd

# send a HUP to the top django process to force a graceful shutdown of the workers
if [ -n "$CURRENT_PID" ]; then
    kill -HUP $CURRENT_PID
fi

# readjust symlinks
ln -T -s -vf $NEW_OMERO ./current
