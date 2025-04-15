#!/bin/bash
set -euo pipefail

args=( "${@}" )
for i in "${!args[@]}"; do
    args[${i}]="$(echo "${args[${i}]}" | envsubst)"
done

exec "${args[@]}"
