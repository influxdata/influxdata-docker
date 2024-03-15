#!/bin/sh
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- chronograf "$@"
fi

if [ "$1" = 'chronograf' ]; then
  export BOLT_PATH=${BOLT_PATH:-/var/lib/chronograf/chronograf-v1.db}
fi

if [ "$(id -u)" -ne 0 ]; then
    exec "$@"
else
    exec su-exec chronograf "$@"
fi
