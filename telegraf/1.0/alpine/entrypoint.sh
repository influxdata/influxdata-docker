#!/bin/sh
set -e

while [ ! -f "/etc/telegraf/telegraf.conf" ]; do
    sleep 1
done

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

exec "$@"
