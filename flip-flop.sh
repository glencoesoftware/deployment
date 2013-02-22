#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Missing 2 dirs to flip between"
    exit 1
fi

current=$( file -b current | awk '{ print $NF }' |sed -e "s/['\`]//g" )
sleep 2s

set -x
if [ "$current" = "$1" ]; then
    ./toggle-omeroweb.sh current $2
else
    ./toggle-omeroweb.sh current $1
fi
