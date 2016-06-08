#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- chronograf "$@"
fi

# TODO remove this for 0.13
if [ "$1" = 'chronograf' ]; then
    shift
    set -- chronograf -config /etc/chronograf/chronograf.conf "$@"
fi

exec "$@"
