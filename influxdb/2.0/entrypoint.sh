#!/bin/bash
set -eo pipefail

# Look for standard config names in the volume configured in our Dockerfile.
declare -r CONFIG_VOLUME=/etc/influxdb2
declare -ra CONFIG_NAMES=(config.json config.toml config.yaml config.yml)

# List of env vars required to auto-run setup or upgrade processes.
declare -ra REQUIRED_INIT_VARS=(INFLUXDB_INIT_USERNAME INFLUXDB_INIT_PASSWORD INFLUXDB_INIT_ORG INFLUXDB_INIT_BUCKET)

# Wait up to a minute for the DB to boot
declare -r STARTUP_PING_WAIT_SECONDS=2
declare -r STARTUP_PING_ATTEMPTS=30

# Allow users to mount arbitrary startup scripts into the container,
# for execution after initial setup/upgrade.
declare -r USER_SCRIPT_DIR=/docker-entrypoint-initdb.d

# Mimic the structured logging used by InfluxDB.
# Usage: log <level> <msg> [<key> <val>]...
function log () {
    local -r level=$1 msg=$2
    shift 2
    local attrs='"system": "docker"'
    while [ "$#" -gt 1 ]; do
        attrs="${attrs}, \"$1\": \"$2\""
        shift 2
    done

    local -r logtime=$(date --utc +'%FT%T.%NZ')
    1>&2 echo -e "${logtime}\t${level}\t${msg}\t{${attrs}}"
}

# Search for a V2 config file, and export its path into the env for influxd to use.
function set_config_path () {
    local config_path=${CONFIG_VOLUME}/default-config.yml

    if [ -n "$INFLUXD_CONFIG_PATH" ]; then
        config_path=${INFLUXD_CONFIG_PATH}
    else
        for name in ${CONFIG_NAMES[@]}; do
            if [ -f ${CONFIG_VOLUME}/${name} ]; then
                config_path=${CONFIG_VOLUME}/${name}
                break
            fi
        done
    fi

    export INFLUXD_CONFIG_PATH=${config_path}
}

# Ensure all env vars required to run influx setup or influxd upgrade are set in the env.
function ensure_init_vars_set () {
    local missing_some=0
    for var in ${REQUIRED_INIT_VARS[@]}; do
        if [ -z "${!var}" ]; then
            log error "missing parameter, cannot init InfluxDB" parameter ${var}
            missing_some=1
        fi
    done
    if [ ${missing_some} = 1 ]; then
        exit 1
    fi
}

# If exiting on error, delete all bolt and engine files.
# If we didn't do this, the container would see the boltdb file on reboot and assume
# the DB is already full set up.
function cleanup_influxd () {
    local -r exit_code=$?
    if [ ${exit_code} != 0 ]; then
        local -r bolt_path=$(influxd print-config --key-name bolt-path ${@})
        local -r engine_path=$(influxd print-config --key-name engine-path ${@})
        
        log warn "cleaning bolt and engine files to prevent conflicts on retry" bolt_path ${bolt_path} engine_path ${engine_path}
        rm -rf ${bolt_path} ${engine_path}
    fi
}

# Upgrade V1 data into the V2 format using influxd upgrade.
# The process will use either a V1 config file or a V1 data dir to drive
# the upgrade, with precedence order:
#   1. Config file pointed to by INFLUXDB_INIT_UPGRADE_V1_CONFIG env var
#   2. Data dir pointed to by INFLUXDB_INIT_UPGRADE_V1_DIR env var
#   3. Config file at /etc/influxdb/influxdb.conf
#   4. Data dir at /var/lib/influxdb
function upgrade_influxd () {
    local -a upgrade_args=(
        --force
        --username ${INFLUXDB_INIT_USERNAME}
        --password ${INFLUXDB_INIT_PASSWORD}
        --org ${INFLUXDB_INIT_ORG}
        --bucket ${INFLUXDB_INIT_BUCKET}
        --v2-config-path ${CONFIG_VOLUME}/config.toml
        --influx-configs-path ${INFLUX_CONFIGS_PATH}
        --continuous-query-export-path ${CONFIG_VOLUME}/v1-cq-export.txt
        --log-level $(influxd print-config --key-name log-level ${@})
        --bolt-path $(influxd print-config --key-name bolt-path ${@})
        --engine-path $(influxd print-config --key-name engine-path ${@})
        --overwrite-existing-v2
    )
    if [ -n "$INFLUXDB_INIT_RETENTION" ]; then
        upgrade_args=(${upgrade_args[@]} --retention ${INFLUXDB_INIT_RETENTION})
    fi

    if [[ -n "$INFLUXDB_INIT_UPGRADE_V1_CONFIG" && -f ${INFLUXDB_INIT_UPGRADE_V1_CONFIG} ]]; then
        upgrade_args=(${upgrade_args[@]} --config-file ${INFLUXDB_INIT_UPGRADE_V1_CONFIG})
    elif [[ -n "$INFLUXDB_INIT_UPGRADE_V1_DIR" && -d ${INFLUXDB_INIT_UPGRADE_V1_DIR} ]]; then
        upgrade_args=(${upgrade_args[@]} --v1-dir ${INFLUXDB_INIT_UPGRADE_V1_DIR})
    elif [ -f etc/influxdb/influxdb.conf ]; then
        upgrade_args=(${upgrade_args[@]} --config-file etc/influxdb/influxdb.conf)
    elif [ -d /var/lib/influxdb ]; then
        upgrade_args=(${upgrade_args[@]} --v1-dir /var/lib/influxdb)
    else
        log error "failed to autodetect usable V1 config or data dir, aborting upgrade"
        exit 1
    fi

    influxd upgrade ${upgrade_args[@]}
    # Reset global influxd config to pick up new file written by the upgrade process.
    set_config_path
}

# Ping influxd until it responds.
# Used to block execution until the server is ready to process setup requests.
function wait_for_influxd () {
    local ping_count=0
    while [ ${ping_count} -lt ${STARTUP_PING_ATTEMPTS} ]; do
        sleep ${STARTUP_PING_WAIT_SECONDS}
        log info "pinging influxd..."
        if influx ping &> /dev/null; then
            log info "got response from influxd, proceeding"
            return
        fi
    done
    log error "failed to detect influxd startup" ping_attempts ${STARTUP_PING_ATTEMPTS}
    exit 1
}

# Create an initial user/org/bucket in the DB using the influx CLI.
function setup_influxd () {
    local -a setup_args=(
        --force
        --username ${INFLUXDB_INIT_USERNAME}
        --password ${INFLUXDB_INIT_PASSWORD}
        --org ${INFLUXDB_INIT_ORG}
        --bucket ${INFLUXDB_INIT_BUCKET}
    )
    if [ -n "$INFLUXDB_INIT_RETENTION" ]; then
        setup_args=(${setup_args[@]} --retention ${INFLUXDB_INIT_RETENTION})
    fi

    influx setup ${setup_args[@]}
}

# Get the IDs of the initial user/org/bucket created during setup, and export them into the env.
# We do this to help with arbitrary user scripts, since many influx CLI commands only take IDs.
function set_init_resource_ids () {
    export INFLUXDB_INIT_USER_ID=$(influx user list -n ${INFLUXDB_INIT_USER} --hide-headers | cut -f 1)
    export INFLUXDB_INIT_ORG_ID=$(influx org list -n ${INFLUXDB_INIT_ORG} --hide-headers | cut -f 1)
    export INFLUXDB_INIT_BUCKET_ID=$(influx bucket list -n ${INFLUXDB_INIT_BUCKET} --hide-headers | cut -f 1)
}

# Execute all shell files mounted into the expected path for user-defined startup scripts.
function run_user_scripts () {
    if [ -d ${USER_SCRIPT_DIR} ]; then
        log info "Executing user-provided scripts" script_dir ${USER_SCRIPT_DIR}
        run-parts --regex ".*sh$" --report --exit-on-error ${USER_SCRIPT_DIR}
    fi
}

# Perform initial setup on the InfluxDB instance, either by setting up fresh metadata
# or by upgrading existing V1 data.
function init_influxd () {
    if [[ ${INFLUXDB_INIT_MODE} != setup && ${INFLUXDB_INIT_MODE} != upgrade ]]; then
        log error "found invalid INFLUXDB_INIT_MODE, valid values are 'setup' and 'upgrade'" INFLUXDB_INIT_MODE ${INFLUXDB_INIT_MODE}
        exit 1
    fi
    ensure_init_vars_set
    trap "cleanup_influxd" EXIT

    # The upgrade process needs to run before we boot the server, otherwise the
    # boltdb file will be generated and cause conflicts.
    if [ ${INFLUXDB_INIT_MODE} = upgrade ]; then
        upgrade_influxd ${@}
    fi

    # Start influxd in the background.
    log info "booting influxd server in the background"
    influxd ${@} &
    local -r influxd_pid="$!"
    wait_for_influxd

    # Use the influx CLI to create an initial user/org/bucket.
    if [ ${INFLUXDB_INIT_MODE} = setup ]; then
        setup_influxd
    fi

    set_init_resource_ids
    run_user_scripts

    log info "initialization complete, bringing influxd to foreground"
    wait ${influxd_pid}
}

# Run influxd, with optional setup logic.
function influxd_main () {
    set_config_path
    local -r bolt_path=$(influxd print-config --key-name bolt-path ${@})
    local -r engine_path=$(influxd print-config --key-name engine-path ${@})

    if test -f ${bolt_path}; then
        log info "found existing boltdb file, skipping setup wrapper" bolt_path ${bolt_path}
        influxd ${@}
    elif [ -z "$INFLUXDB_INIT_MODE" ]; then
        log warn "boltdb not found at configured path, but INFLUXDB_INIT_MODE not specified, skipping setup wrapper" bolt_path ${bolt_path}
        influxd ${@}
    else 
        init_influxd ${@}
    fi
}

function main () {
    if [[ $# = 0 || "${1:0:1}" = '-' ]]; then
        # No command given, assume influxd.
        influxd_main ${@}
    elif [[ "$1" = 'influxd' && ($# = 1 || "${2:0:1}" = '-') ]]; then
        # influxd w/ no subcommand.
        shift 1
        influxd_main ${@}
    else
        # influxd w/ subcommand OR something else entirely.
        exec ${@}
    fi
}

main ${@}
