#!/bin/bash
set -eo pipefail


## READ ME
##
## This script handles a few use-cases:
##   1. Running subcommands of `influx`
##


function main () {
    influx "${@}"
}

main "${@}"
