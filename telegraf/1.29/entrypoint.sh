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

    # honor groups supplied via 'docker run --group-add ...' but drop 'root'
    # (also removes 'telegraf' since we unconditionally add it and don't want it listed twice)
    # see https://github.com/influxdata/influxdata-docker/issues/724
    groups="telegraf"
    extra_groups="$(id -Gn || true)"
    for group in $extra_groups; do
        case "$group" in
            root | telegraf) ;;
            *) groups="$groups,$group" ;;
        esac
    done
    exec setpriv --reuid telegraf --regid telegraf --groups "$groups" "$@"
fi
