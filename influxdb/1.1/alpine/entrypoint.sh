#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- influxd "$@"
fi

AUTH_ENABLED="$INFLUXDB_HTTP_AUTH_ENABLED"

if [ -z "$AUTH_ENABLED" ]; then
	AUTH_ENABLED="$(grep -iE '^\s*auth-enabled\s*=\s*true' /etc/influxdb/influxdb.conf | grep -io 'true' | cat)"
else
	AUTH_ENABLED=$(echo "$INFLUXDB_HTTP_AUTH_ENABLED" | grep -io 'true' | cat)
fi

if ( [ ! -z "$AUTH_ENABLED" ] || [ ! -z "$INFLUXDB_DB" ] ) && [ ! "$(ls -A /var/lib/influxdb)" ]; then

	INIT_QUERY=""
	CREATE_DB_QUERY="q=CREATE DATABASE $INFLUXDB_DB"

	if [ ! -z "$AUTH_ENABLED" ]; then

		if [ -z "$INFLUXDB_ADMIN_USER" ]; then
			INFLUXDB_ADMIN_USER="admin"
		fi

		if [ -z "$INFLUXDB_ADMIN_PASSWORD" ]; then
			INFLUXDB_ADMIN_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32;echo;)"
			echo "INFLUXDB_ADMIN_PASSWORD:$INFLUXDB_ADMIN_PASSWORD"
		fi

		INIT_QUERY="q=CREATE USER $INFLUXDB_ADMIN_USER WITH PASSWORD '$INFLUXDB_ADMIN_PASSWORD' WITH ALL PRIVILEGES"
	elif [ ! -z "$INFLUXDB_DB" ]; then
		INIT_QUERY="$CREATE_DB_QUERY"
	fi

	"$@" &
	pid="$!"

	for i in {30..0}; do
		if curl -i -XPOST http://127.0.0.1:8086/query --data-urlencode "$INIT_QUERY"; then
			break
		fi
		echo 'influxdb init process in progress...'
		sleep 1
	done

	if [ "$i" = 0 ]; then
		echo >&2 'influxdb init process failed.'
		exit 1
	fi

	if [ ! -z "$AUTH_ENABLED" ]; then

		CURL_CMD="curl -i -XPOST http://127.0.0.1:8086/query -u${INFLUXDB_ADMIN_USER}:${INFLUXDB_ADMIN_PASSWORD} --data-urlencode "

		if [ ! -z "$INFLUXDB_DB" ]; then
			$CURL_CMD "$CREATE_DB_QUERY"
		fi

		if [ ! -z "$INFLUXDB_USER" ] && [ -z "$INFLUXDB_USER_PASSWORD" ]; then
			INFLUXDB_USER_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32;echo;)"
			echo "INFLUXDB_USER_PASSWORD:$INFLUXDB_USER_PASSWORD"
		fi

		if [ ! -z "$INFLUXDB_USER" ]; then
			$CURL_CMD "q=CREATE USER $INFLUXDB_USER WITH PASSWORD '$INFLUXDB_USER_PASSWORD'"

			$CURL_CMD "q=REVOKE ALL PRIVILEGES FROM ""$INFLUXDB_USER"""

			if [ ! -z "$INFLUXDB_DB" ]; then
				$CURL_CMD "q=GRANT READ ON ""$INFLUXDB_DB"" TO ""$INFLUXDB_USER"""
				$CURL_CMD "q=GRANT WRITE ON ""$INFLUXDB_DB"" TO ""$INFLUXDB_USER"""
			fi
		fi

		if [ ! -z "$INFLUXDB_WRITE_USER" ] && [ -z "$INFLUXDB_WRITE_USER_PASSWORD" ]; then
			INFLUXDB_WRITE_USER_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32;echo;)"
			echo "INFLUXDB_WRITE_USER_PASSWORD:$INFLUXDB_WRITE_USER_PASSWORD"
		fi

		if [ ! -z "$INFLUXDB_WRITE_USER" ]; then
			$CURL_CMD "q=CREATE USER $INFLUXDB_WRITE_USER WITH PASSWORD '$INFLUXDB_WRITE_USER_PASSWORD'"
			$CURL_CMD "q=REVOKE ALL PRIVILEGES FROM ""$INFLUXDB_WRITE_USER"""

			if [ ! -z "$INFLUXDB_DB" ]; then
				$CURL_CMD "q=GRANT WRITE ON ""$INFLUXDB_DB"" TO ""$INFLUXDB_WRITE_USER"""
			fi
		fi

		if [ ! -z "$INFLUXDB_READ_USER" ] && [ -z "$INFLUXDB_READ_USER_PASSWORD" ]; then
			INFLUXDB_READ_USER_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32;echo;)"
			echo "INFLUXDB_READ_USER_PASSWORD:$INFLUXDB_READ_USER_PASSWORD"
		fi

		if [ ! -z "$INFLUXDB_READ_USER" ]; then
			$CURL_CMD "q=CREATE USER $INFLUXDB_READ_USER WITH PASSWORD '$INFLUXDB_READ_USER_PASSWORD'"
			$CURL_CMD "q=REVOKE ALL PRIVILEGES FROM ""$INFLUXDB_READ_USER"""

			if [ ! -z "$INFLUXDB_DB" ]; then
				$CURL_CMD "q=GRANT READ ON ""$INFLUXDB_DB"" TO ""$INFLUXDB_READ_USER"""
			fi
		fi

	fi

	if ! kill -s TERM "$pid" || ! wait "$pid"; then
		echo >&2 'influxdb init process failed. (Could not stop influxdb)'
		exit 1
	fi

fi

if [ -z "$INFLUXDB_INIT_ONLY" ]; then
	exec "$@"
fi