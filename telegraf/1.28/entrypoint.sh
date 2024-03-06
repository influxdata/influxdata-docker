#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

if [ $EUID -ne 0 ]; then
    exec "$@"
else
    # Allow telegraf to send ICMP packets and bind to privliged ports
    setcap cap_net_raw,cap_net_bind_service+ep /usr/bin/telegraf || echo "Failed to set additional capabilities on /usr/bin/telegraf"

    # ensure HOME is set to the telegraf user's home dir
    export HOME=$(getent passwd telegraf | cut -d : -f 6)

    # honor groups supplied via 'docker run --group-add ...' but drop 'root' (the sed
    # removes 'telegraf' since we unconditionally add it and don't want it listed twice)
    groups="telegraf"
    extra_groups="$(id -Gn | sed \
    -e 's/ /,/g' \
    -e 's/,\(root\|telegraf\),/,/g' \
    -e 's/^\(root\|telegraf\),//g'  \
    -e 's/,\(root\|telegraf\)$//g' \
    -e 's/^\(root\|telegraf\)$//g')"
    if [ -n "$extra_groups" ]; then
        groups="$groups,$extra_groups"
    fi
    exec setpriv --reuid telegraf --regid telegraf --groups "$groups" "$@"
fi
