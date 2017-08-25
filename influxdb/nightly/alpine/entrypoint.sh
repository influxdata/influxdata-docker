#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- influxd "$@"
fi

if [ "$1" = 'influxd' ]; then
	/init-influxdb.sh "${@:2}"
fi

if [ -z "$INFLUXDB_INIT_ONLY" ]; then
	exec "$@"
fi
