#!/bin/sh
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

if [ "$EUID" -ne 0 ]; then
    exec "$@"
else
    exec su-exec telegraf "$@"
fi
