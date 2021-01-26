#!/bin/bash
set -eo pipefail

# Do our best to match the logging requested by the user running the container.
declare -rA LOG_LEVELS=([error]=0 [warn]=1 [info]=2 [debug]=3)
declare LOG_LEVEL=error

# Mimic the structured logging used by InfluxDB.
# Usage: log <level> <msg> [<key> <val>]...
function log () {
    local -r level=$1 msg=$2
    shift 2

    if [ ${LOG_LEVELS[${level}]} -gt ${LOG_LEVELS[${LOG_LEVEL}]} ]; then
        return
    fi

    local attrs='"system": "docker"'
    while [ "$#" -gt 1 ]; do
        attrs="${attrs}, \"$1\": \"$2\""
        shift 2
    done

    local -r logtime=$(date --utc +'%FT%T.%NZ')
    1>&2 echo -e "${logtime}\t${level}\t${msg}\t{${attrs}}"
}

# Set the global log-level for the entry-point to match the config passed to influxd.
function set_global_log_level () {
    local level="$(influxd print-config --key-name log-level ${@})"
    if [ -z "${LOG_LEVELS[${level}]}" ]; then
        log error "Invalid log-level specified, using 'error'" level ${level}
    fi
    LOG_LEVEL=${level}
}

# Look for standard config names in the volume configured in our Dockerfile.
declare -r CONFIG_VOLUME=/etc/influxdb2
declare -ra CONFIG_NAMES=(config.json config.toml config.yaml config.yml)

# Search for a V2 config file, and export its path into the env for influxd to use.
function set_config_path () {
    local config_path=/etc/defaults/influxdb2/config.yml

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

function set_data_paths () {
    export BOLT_PATH=$(influxd print-config --key-name bolt-path ${@})
    export ENGINE_PATH=$(influxd print-config --key-name engine-path ${@})
}

# Ensure all the data directories needed by influxd exist with the right permissions.
function create_directories () {
    local -r bolt_dir=$(dirname ${BOLT_PATH})
    local user=$(id -u)

    mkdir -p ${bolt_dir} ${ENGINE_PATH}
    chmod 700 ${bolt_dir} ${ENGINE_PATH} || :

    mkdir -p ${CONFIG_VOLUME} || :
    chmod 775 ${CONFIG_VOLUME} || :

    if [ ${user} = 0 ]; then
        find ${bolt_dir} \! -user influxdb -exec chown influxdb '{}' +
        find ${ENGINE_PATH} \! -user influxdb -exec chown influxdb '{}' +
        find ${CONFIG_VOLUME} \! -user influxdb -exec chown influxdb '{}' +
    fi
}

# List of env vars required to auto-run setup or upgrade processes.
declare -ra REQUIRED_INIT_VARS=(INFLUXDB_INIT_USERNAME INFLUXDB_INIT_PASSWORD INFLUXDB_INIT_ORG INFLUXDB_INIT_BUCKET)

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
    log warn "cleaning bolt and engine files to prevent conflicts on retry" bolt_path ${BOLT_PATH} engine_path ${ENGINE_PATH}
    rm -rf ${BOLT_PATH} ${ENGINE_PATH}
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
        --log-path ${CONFIG_VOLUME}/upgrade.log
        --log-level ${LOG_LEVEL}
        --bolt-path ${BOLT_PATH}
        --engine-path ${ENGINE_PATH}
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

# Wait up to a minute for the DB to boot
declare -r STARTUP_PING_WAIT_SECONDS=2
declare -r STARTUP_PING_ATTEMPTS=30

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

# Configure the INFLUX_HOST env var so the influx CLI knows how to reach the server for initial setup.
function set_influx_host () {
    export INFLUX_HOST="$(influxd print-config --key-name http-bind-address ${@} | sed -E 's#[^:]*:(.*)#http://localhost:\1#g')"
}

# Get the IDs of the initial user/org/bucket created during setup, and export them into the env.
# We do this to help with arbitrary user scripts, since many influx CLI commands only take IDs.
function set_init_resource_ids () {
    export INFLUXDB_INIT_USER_ID=$(influx user list -n ${INFLUXDB_INIT_USER} --hide-headers | cut -f 1)
    export INFLUXDB_INIT_ORG_ID=$(influx org list -n ${INFLUXDB_INIT_ORG} --hide-headers | cut -f 1)
    export INFLUXDB_INIT_BUCKET_ID=$(influx bucket list -n ${INFLUXDB_INIT_BUCKET} --hide-headers | cut -f 1)
}

# Allow users to mount arbitrary startup scripts into the container,
# for execution after initial setup/upgrade.
declare -r USER_SCRIPT_DIR=/docker-entrypoint-initdb.d

# Execute all shell files mounted into the expected path for user-defined startup scripts.
function run_user_scripts () {
    if [ -d ${USER_SCRIPT_DIR} ]; then
        log info "Executing user-provided scripts" script_dir ${USER_SCRIPT_DIR}
        run-parts --regex ".*sh$" --report --exit-on-error ${USER_SCRIPT_DIR}
    fi
}

# When we run setup logic, we boot influxd in the background instead of `exec`-ing it.
# By default this prevents signals from reaching the server, so we register traps to
# pass through the signals that matter.
# The PID of the influxd process is tracked globally so the trap handlers can send it signals.
declare INFLUXD_PID=""

function handle_term () {
    if [ -n "$INFLUXD_PID" ]; then
        kill -TERM ${INFLUXD_PID}
        wait ${INFLUXD_PID}
    fi
}

function handle_int () {
    if [ -n "$INFLUXD_PID" ]; then
        kill -INT ${INFLUXD_PID}
        wait ${INFLUXD_PID}
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
        upgrade_influxd
    fi

    # Start influxd in the background.
    log info "booting influxd server in the background"
    trap handle_term TERM
    trap handle_int INT
    influxd ${@} &
    INFLUXD_PID="$!"

    set_influx_host ${@}
    wait_for_influxd

    # Use the influx CLI to create an initial user/org/bucket.
    if [ ${INFLUXDB_INIT_MODE} = setup ]; then
        setup_influxd
    fi

    set_init_resource_ids
    run_user_scripts

    log info "initialization complete, bringing influxd to foreground"
    trap - EXIT
    wait ${INFLUXD_PID}
}

# Run influxd, with optional setup logic.
function influxd_main () {
    if test -f ${BOLT_PATH}; then
        log info "found existing boltdb file, skipping setup wrapper" bolt_path ${BOLT_PATH}
        exec influxd ${@}
    elif [ -z "$INFLUXDB_INIT_MODE" ]; then
        log warn "boltdb not found at configured path, but INFLUXDB_INIT_MODE not specified, skipping setup wrapper" bolt_path ${bolt_path}
        exec influxd ${@}
    else
        init_influxd ${@}
    fi
}

function main () {
    # Ensure INFLUXD_CONFIG_PATH is set.
    # We do this even if we're not running the main influxd server so subcommands
    # (i.e. print-config) still find the right config values.
    set_config_path

    local run_influxd=false
    if [[ $# = 0 || "$1" = run || "${1:0:1}" = '-' ]]; then
        run_influxd=true
    elif [[ "$1" = influxd && ($# = 1 || "$2" = run || "${2:0:1}" = '-') ]]; then
        run_influxd=true
        shift 1
    fi

    if ${run_influxd}; then
        if [ "$1" = run ]; then
            shift 1
        fi

        # Configure logging for our wrapper.
        set_global_log_level ${@}
        # Configure data paths used across functions.
        set_data_paths ${@}
        # Ensure volume directories exist w/ correct permissions.
        create_directories
    fi

    if [ $(id -u) = 0 ]; then
        exec gosu influxdb "$BASH_SOURCE" ${@}
        return
    fi

    if ${run_influxd}; then
        influxd_main ${@}
    else
        exec ${@}
    fi
}

main ${@}
