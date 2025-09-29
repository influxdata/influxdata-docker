#!/bin/bash
set -euo pipefail

args=("${@}")

if [[ "${args[0]:-}" == serve ]] ; then
    args=(influxdb3 "${args[@]}")
fi

if [[ "${args[0]:-}" =~ ^- ]] ; then
    args=(influxdb3 serve "${args[@]}")
fi

if [[ "${args[0]:-}" == influxdb3 ]] ; then
    for i in "${!args[@]}"; do
        args[i]="$(envsubst <<<"${args[i]}")"
    done
fi

exec "${args[@]}"
