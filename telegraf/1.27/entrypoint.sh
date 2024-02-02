#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

if [ $EUID -ne 0 ]; then
    exec "$@"
else
    export HOME=$(getent passwd telegraf | cut -d : -f 6)
    # attempt to set the fscaps on the telegraf binary then limit telegraf to only
    # being able to inherit those capabilities
    if setcap cap_net_raw,cap_net_bind_service+ep /usr/bin/telegraf ; then
        exec setpriv --reuid telegraf --regid telegraf --groups telegraf --bounding-set=-all,+net_raw,+net_bind_service --inh-caps=-all,+net_raw,+net_bind_service "$@"
    else
        echo "Failed to set additional capabilities on /usr/bin/telegraf"
        exec setpriv --reuid telegraf --regid telegraf --groups telegraf "$@"
    fi
fi
