#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- kapacitord "$@"
fi

# TODO remove -config from this for 0.13 (leaving -log-file only)
if [ "$1" = 'kapacitord' ]; then
    shift
    if [ $# -gt 0 ]; then
        case $1 in
          config)
            shift
            set -- kapacitord config -config /etc/kapacitor/kapacitor.conf "$@"
            ;;
          run)
            shift
            set -- kapacitord run -config /etc/kapacitor/kapacitor.conf -log-file STDERR "$@"
            ;;
          -*)
            set -- kapacitord -config /etc/kapacitor/kapacitor.conf -log-file STDERR "$@"
            ;;
          *)
            set -- kapacitord "$@"
            ;;
        esac
    else
        set -- kapacitord -config /etc/kapacitor/kapacitor.conf -log-file STDERR
    fi
fi

KAPACITOR_HOSTNAME=${KAPACITOR_HOSTNAME:-$HOSTNAME}
export KAPACITOR_HOSTNAME

exec "$@"
