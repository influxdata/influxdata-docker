declare -r ATTEMPTS=30

declare -r TEST_USER=username
declare -r TEST_PASSWORD=password
declare -r TEST_ORG=org
declare -r TEST_BUCKET=bucket
declare -r TEST_RETENTION_SECONDS=604800
declare -r TEST_ADMIN_TOKEN=supersecrettoken12345

declare -r TEST_V1_DB=telegraf
declare -r TEST_V1_RP=autogen
declare -r TEST_V1_USER=v1-reader
declare -r TEST_V1_PASSWORD=v1-password
declare -r TEST_CREATE_DBRP_SCRIPT=$(cat <<EOF
#!/bin/bash
set -e

influx v1 dbrp create \
  --bucket-id \$INFLUXDB_INIT_BUCKET_ID \
  --db ${TEST_V1_DB} \
  --rp ${TEST_V1_RP} \
  --default \
  --org \$INFLUXDB_INIT_ORG
EOF
)
declare -r TEST_CREATE_V1_AUTH_SCRIPT=$(cat <<EOF
#!/bin/bash
set -e

influx v1 auth create \
  --username ${TEST_V1_USER} \
  --password ${TEST_V1_PASSWORD} \
  --read-bucket \$INFLUXDB_INIT_BUCKET_ID \
  --org \$INFLUXDB_INIT_ORG
EOF
)

function log_msg () {
  echo "[$(date '+%Y/%m/%d %H:%M:%S %z')]" ${@}
}

function wait_container_ready () {
    local attempt_count=0

    while [ ${attempt_count} -lt ${ATTEMPTS} ]; do
        if curl -s localhost:8086/health >/dev/null; then
            return 0
        fi
        sleep 2
        attempt_count=$((attempt_count + 1))
    done
    log_msg Error: container did not start up in time
    return 1
}

function extract_token () {
    docker exec -i ${1} influx auth list --user ${TEST_USER} --hide-headers | cut -f 3
}

function join_array () {
    local IFS=,
    echo "$*"
}
