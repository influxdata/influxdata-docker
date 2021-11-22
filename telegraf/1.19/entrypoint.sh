#!/bin/bash
set -e

# Allow telegraf to send ping packages and bind to privliged ports
setcap cap_net_raw,cap_net_bind_service+ep /usr/bin/telegraf

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

if [ $EUID -ne 0 ]; then
    exec "$@"
else
    exec setpriv --reuid telegraf --init-groups "$@"
fi
