#!/bin/bash
set -e

USER_ID=${INFLUXDB_RUNAS_USER_ID:-0}
GROUP_ID=${INFLUXDB_RUNAS_GROUP_ID:-0}

if [ $USER_ID != 0 ]; then
  if [ $USER_ID != $(id -u influxdb) ]; then
    echo "Changing uid of influxdb to $USER_ID"
    usermod -u $USER_ID influxdb
  fi
fi

if [ $GROUP_ID != 0 ]; then
  if [ $GROUP_ID != $(id -g influxdb) ]; then
    echo "Changing gid of influxdb to $GROUP_ID"
    groupmod -o -g $GROUP_ID influxdb
  fi
fi

if [ $USER_ID != 0 ]; then
  echo "Changing ownership of /var/lib/influxdb to $USER_ID:$GROUP_ID"
  chown -R ${USER_ID}:${GROUP_ID} /var/lib/influxdb
fi

if [ $USER_ID != 0 ]; then
    GOSU_CMD="gosu influxdb"
else
    GOSU_CMD=
fi

echo "Starting influxdb as uid $USER_ID and gid $GROUP_ID"

if [ "${1:0:1}" = '-' ]; then
    set -- influxd "$@"
fi

if [ "$1" = 'influxd' ]; then
    $GOSU_CMD /init-influxdb.sh "${@:2}"
fi

exec $GOSU_CMD "$@"
