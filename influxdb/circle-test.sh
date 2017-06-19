#!/bin/bash

container_counter=1

influx() {
  ./.tests/influx -host 127.0.0.1 -port 8086 -format=csv -execute "$@"
}

setup() {

  mkdir -p ./.tests/var/lib/influxdb

  local rm_flag='--rm'

  if [ ! -z "$CIRCLE_BUILD_NUM" ]; then
    rm_flag=''
  fi

  PORT=$2

  if [ -z "$PORT" ]; then
    PORT=8086
  fi

  local init_cmd="docker run -it $rm_flag -p 8086:$PORT --user=$(id -u):0 -v $(pwd)/.tests/var/lib/influxdb:/var/lib/influxdb $1 ""$tag"" /init-influxdb.sh"

  if ! $init_cmd > /dev/null; then
    failed_tests+=("Failed to execute '$init_cmd'")
  fi

  docker run -d --name influxdb-test$container_counter -p 8086:$PORT --user=$(id -u):0 -v $(pwd)/.tests/var/lib/influxdb:/var/lib/influxdb $1 "$tag" > /dev/null

  # Copy cli from started container
  docker cp influxdb-test$container_counter:/usr/bin/influx ./.tests/influx

  # Wait until influxdb is healthy
  for i in {30..0}; do
    if curl -s -i -XHEAD http://127.0.0.1:8086/ping > /dev/null; then
      break
    fi
    sleep 1
  done
}

cleanup() {
  docker stop influxdb-test$container_counter > /dev/null

  if [ -z "$CIRCLE_BUILD_NUM" ]; then
    docker rm influxdb-test$container_counter > /dev/null
  fi

  container_counter=$((container_counter + 1))

  rm -r ./.tests
}

test_default_without_auth_enabled() {
  log_msg 'Executing test_default_without_auth_enabled'
  setup

  assert_equals "$(influx 'SHOW DATABASES' | wc -l)" '1' "test_default_without_auth_enabled: influxdb should contain no databases"

  assert_equals "$(influx 'SHOW USERS' | wc -l)" '1' "test_default_without_auth_enabled: influxdb should contain no users"

  cleanup
}

test_default_with_auth_enabled() {
  log_msg 'Executing test_default_with_auth_enabled'
  setup '--env INFLUXDB_HTTP_AUTH_ENABLED=true'

  assert_contains "$(influx 'SHOW DATABASES' 2> /dev/null)" 'create admin user first or disable authentication' 'test_default_with_auth_enabled: influxdb should not be initialized'

  cleanup
}

test_create_db() {
  log_msg 'Executing test_create_db'
  setup '--env INFLUXDB_DB=test_db'

  assert_contains "$(influx 'SHOW DATABASES')" 'test_db' 'test_create_db: influxdb should contain a test_db database'

  cleanup
}

test_create_admin() {
  log_msg 'Executing test_create_admin'
  setup '--env INFLUXDB_HTTP_AUTH_ENABLED=true --env INFLUXDB_ADMIN_USER=test_admin --env INFLUXDB_ADMIN_PASSWORD=123'

  influx 'SHOW USERS' -username test_admin -password=123 > /dev/null

  local exit_code="$?"

  assert_equals "$exit_code" '0' 'test_create_admin: influxdb should contain a test_admin user'

  cleanup
}

test_create_user() {
  log_msg 'Executing test_create_user'
  setup '--env INFLUXDB_DB=test_db --env INFLUXDB_HTTP_AUTH_ENABLED=true --env INFLUXDB_ADMIN_USER=admin --env INFLUXDB_USER=test_user --env INFLUXDB_USER_PASSWORD=123'

  local result="$(influx 'INSERT test_measurement value=1' -database=test_db -username test_user -password=123)"

  assert_equals "$result" '' 'test_create_user: influxdb user ''test_user'' should exist and have write privileges'

  local success=$(influx 'SELECT * FROM test_measurement;' -database=test_db -username test_user -password=123 > /dev/null && echo 'true')

  assert_equals "$success" 'true' 'test_create_user: influxdb user ''test_user'' should have read privileges'

  cleanup
}

test_create_write_user() {
  log_msg 'Executing test_create_write_user'
  setup '--env INFLUXDB_DB=test_db --env INFLUXDB_HTTP_AUTH_ENABLED=true --env INFLUXDB_ADMIN_USER=admin --env INFLUXDB_WRITE_USER=test_write_user --env INFLUXDB_WRITE_USER_PASSWORD=123'

  local result="$(influx 'INSERT test_measurement value=1' -database=test_db -username test_write_user -password=123)"

  assert_equals "$result" '' 'test_create_write_user: influxdb user ''test_write_user'' should exist and have write privileges'

  local success=$(influx 'SELECT * FROM test_measurement' -database=test_db -username test_write_user -password=123 &> /dev/null || echo 'true')

  assert_equals "$success" 'true' 'test_create_write_user: influxdb user ''test_write_user'' should not have read privileges'

  cleanup
}

test_create_read_user() {
  log_msg 'Executing test_create_read_user'
  setup '--env INFLUXDB_DB=test_db --env INFLUXDB_HTTP_AUTH_ENABLED=true --env INFLUXDB_ADMIN_USER=admin --env INFLUXDB_READ_USER=test_read_user --env INFLUXDB_READ_USER_PASSWORD=123'

  local result="$(influx 'INSERT test_measurement value=1' -database=test_db -username test_read_user -password=123)"

  assert_contains "$result" 'not authorized' 'test_create_read_user: influxdb user ''test_read_user'' should not have write privileges'

  local success=$(influx 'SELECT * FROM test_measurement' -database=test_db -username test_read_user -password=123 > /dev/null && echo 'true')

  assert_equals "$success" 'true' 'test_create_read_user: influxdb user ''test_read_user'' should exist and have read privileges'

  cleanup
}

test_custom_shell_script() {
  log_msg 'Executing test_custom_shell_script'

  mkdir -p ./.tests

  echo 'echo ''success'' > /var/lib/influxdb/test_result' > ./.tests/custom_script.sh

  chmod 755 ./.tests/custom_script.sh

  setup "-v $(pwd)/.tests/custom_script.sh:/docker-entrypoint-initdb.d/custom_script.sh"

  local result=$(cat ./.tests/var/lib/influxdb/test_result)

  assert_equals "$result" 'success' 'test_custom_shell_script: test failed'

  cleanup
}

test_custom_iql_script() {
  log_msg 'Executing test_custom_iql_script'

  mkdir -p ./.tests

  local cmd="CREATE USER test_user WITH PASSWORD '123'"

  echo "$cmd" > ./.tests/custom_script.iql

  setup "-v $(pwd)/.tests/custom_script.iql:/docker-entrypoint-initdb.d/custom_script.iql --env INFLUXDB_HTTP_AUTH_ENABLED=true --env INFLUXDB_ADMIN_USER=admin --env INFLUXDB_ADMIN_PASSWORD=123"

  local result=$(influx 'SHOW USERS' -username admin -password=123)

  assert_contains "$result" 'test_user' 'test_custom_iql_script: test failed'

  cleanup
}

test_create_db_on_non_default_port() {
  log_msg 'Executing test_create_db_on_non_default_port'
  setup '--env INFLUXDB_DB=test_db --env INFLUXDB_HTTP_BIND_ADDRESS=:8083' 8083

  assert_contains "$(influx 'SHOW DATABASES')" 'test_db' 'test_create_db: influxdb should contain a test_db database'

  cleanup
}

influxdb_dockerfiles=$(find 'influxdb' -name nightly -prune -o -name Dockerfile -print0 | xargs -0 -I{} dirname {} | sed 's@^./@@' | sed 's@//*@/@g')

for path in $influxdb_dockerfiles; do
  # Generate a tag by replacing the first slash with a colon and all remaining slashes with a dash.
  tag=$(echo $path | sed 's@/@:@' | sed 's@/@-@g')

  log_msg "Testing docker image $tag"

  test_default_without_auth_enabled

  test_default_with_auth_enabled

  test_create_db

  test_create_admin

  test_create_user

  test_create_write_user

  test_create_read_user

  test_custom_shell_script

  test_custom_iql_script

  test_create_db_on_non_default_port

done
