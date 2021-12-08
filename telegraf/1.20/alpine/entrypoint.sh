#!/bin/sh
set -e

# Allow telegraf to send ICMP packets and bind to privliged ports
setcap cap_net_raw,cap_net_bind_service+ep /usr/bin/telegraf

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

if [ "$(id -u)" -ne 0 ]; then
    exec "$@"
else
    exec su-exec telegraf "$@"
fi
