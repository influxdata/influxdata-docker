#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

# TODO remove this for 0.13
if [ "$1" = 'telegraf' ]; then
    shift
    set -- telegraf -config /etc/telegraf/telegraf.conf "$@"
fi

exec "$@"
