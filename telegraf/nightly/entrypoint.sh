#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

if [ $EUID -ne 0 ]; then
    exec "$@"
else
    export HOME=$(getent passwd telegraf | cut -d : -f 6)
    exec setpriv --reuid telegraf --regid telegraf --groups telegraf --bounding-set=-all,+net_raw,+net_bind_service --inh-caps=-all,+net_raw,+net_bind_service "$@"
fi
