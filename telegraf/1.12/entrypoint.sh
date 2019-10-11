#!/bin/bash
set -e


# You can also set the TELEGRAF_CONFIG_CONTENT environment variable to pass some
# Telegraf configuration without having to bind any volumes.
# This is very usefull within kuberentes: the problem of using configmaps is that 
# a change to a config doesn't restart telegraf
if [ -n "$TELEGRAF_CONFIG_CONTENT" ]; then
    echo "$TELEGRAF_CONFIG_CONTENT" > "/etc/telegraf/telegraf.conf"
fi

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

exec "$@"
