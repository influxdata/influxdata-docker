#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- influxd "$@"
fi

/init-influxdb.sh "$@"

if [ -z "$INFLUXDB_INIT_ONLY" ]; then
	exec "$@"
fi
