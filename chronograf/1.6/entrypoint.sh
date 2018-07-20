#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- chronograf "$@"
fi

if [ "$1" = 'chronograf' ]; then
  export BOLT_PATH=${BOLT_PATH:-/var/lib/chronograf/chronograf-v1.db}
fi

exec "$@"
