#!/bin/sh
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- kapacitord "$@"
fi

KAPACITOR_HOSTNAME=${KAPACITOR_HOSTNAME:-$HOSTNAME}
export KAPACITOR_HOSTNAME

if [ "$(id -u)" -ne 0 ] || [ "${KAPACITOR_AS_ROOT}" = "true" ]; then
    exec "$@"
else
    exec setpriv --reuid kapacitor --regid kapacitor --init-groups "$@"
fi
