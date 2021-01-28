#!/usr/bin/env bash
set -eo pipefail

declare -r SCRIPT_DIR=$(cd $(dirname $0) >/dev/null 2>&1 && pwd)
declare -r TESTCASE_DIR=${SCRIPT_DIR}/cases
declare -r IMG_DIR=$(dirname ${SCRIPT_DIR})

declare -r TMP=${SCRIPT_DIR}/tmp
declare -r LOGS=${SCRIPT_DIR}/logs

source ${TESTCASE_DIR}/common.sh

#####################
##### UTILITIES #####
#####################

function ensure_jq () {
    if ! which jq > /dev/null; then
        log_msg Error: 'jq' required to run tests
        exit 1
    fi
}

function tag_suffix () {
    if [ -n "$CIRCLE_BUILD_NUM" ]; then
        echo ${CIRCLE_BUILD_NUM}
    else
        date '+%Y-%m-%dT%H-%M-%S'
    fi
}

###########################
##### SETUP / CLEANUP #####
###########################

# Reuse a 1.x data zip from influxdb's tests to save time/effort.
declare -r INFLUXDB_1x_DATA_COMMIT=c62d3f2d8df917ce06741e98a72b7763fff875c8
declare -r INFLUXDB_1x_DATA_URL=https://github.com/influxdata/influxdb/raw/${INFLUXDB_1x_DATA_COMMIT}/cmd/influxd/upgrade/testdata/v1db.zip

function get_1x_data () {
    curl -sL -o ${TMP}/data.zip ${INFLUXDB_1x_DATA_URL}
    unzip -qq ${TMP}/data.zip -d ${TMP}
    rm ${TMP}/data.zip
}

function cleanup () {
    local -ra leftover_containers=($(docker ps -a -q -f name=*${suffix}))
    if [ ${#leftover_containers[@]} -gt 0 ]; then
        log_msg Cleaning up leftover containers...
        docker stop ${leftover_containers[@]}
        docker rm ${leftover_containers[@]}
    fi
    docker image rm -f influxdb:2.0-${1}
}

#######################
##### ENTRY-POINT #####
#######################

function main () {
    ensure_jq

    local -r suffix=$(tag_suffix)
    trap "cleanup ${suffix}" EXIT

    log_msg Building test images
    docker build -t influxdb:2.0-${suffix} ${IMG_DIR}/2.0

    rm -rf ${TMP} ${LOGS}
    mkdir -p ${TMP} ${LOGS}

    log_msg Downloading 1.x data archive
    get_1x_data

    local -ra tests=($(find ${TESTCASE_DIR} -name 'test-*'))
    local -a failed_tests=()

    for script in ${tests[@]}; do
        local tc=$(basename ${script})

        if [[ $# > 0 && ${tc} != "$1" ]]; then
            continue
        fi

        for prefix in 2.0; do
            # Define standard variables for the test case.
            local tag=${prefix}-${suffix}
            local container=${tc}_${suffix}
            local data=${TMP}/${tc}/${prefix}/data
            local config=${TMP}/${tc}/${prefix}/config
            local logs=${LOGS}/${tc}/${prefix}
            local scripts=${TMP}/${tc}/${prefix}/scripts
            mkdir -p ${data} ${config} ${logs} ${scripts}

            local description="${tc} (${prefix})"
            log_msg Running test "${description}"...
            set +e
            ${script} ${tag} ${container} ${data} ${config} ${logs} ${scripts}
            local test_status=$?
            set -e
            if [ ! ${test_status} -eq 0 ]; then
                failed_tests+=("${description}")
                docker logs ${container} > ${logs}/docker-stdout.log 2> ${logs}/docker-stderr.log || true
            fi
            log_msg Cleaning up test "${description}"...
            docker stop ${container} >/dev/null && docker rm ${container} >/dev/null || true
        done
    done

    if [ ${#failed_tests[@]} -eq 0 ]; then
        log_msg All tests succeeded
    else
        log_msg Some tests failed:
        for tc in "${failed_tests[@]}"; do
            echo -e "\t${tc}"
        done
        exit 1
    fi
}

main ${@}
