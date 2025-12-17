#!/bin/bash
set -euo pipefail

# Unset environment variables; splitting on whitespace
# Usage: INFLUXDB3_UNSET_VARS="HOST FOO BAR"
if [[ -n "${INFLUXDB3_UNSET_VARS:-}" ]]; then
    read -ra vars <<< "${INFLUXDB3_UNSET_VARS}"
    for var in "${vars[@]}"; do
        unset "$var" || { echo "Error: Failed to unset variable '$var' (may be readonly)"; exit 1; }
    done
fi

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
