#!/bin/bash
set -euo pipefail

args=("${@}")

if [[ "${1}" == influxdb3 ]] ; then
    for i in "${!args[@]}"; do
        args[i]="$(envsubst <<<"${args[i]}")"
    done
fi

exec "${args[@]}"
