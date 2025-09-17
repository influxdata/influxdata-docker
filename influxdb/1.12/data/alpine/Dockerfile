FROM alpine:3.21

RUN apk add --no-cache tzdata bash ca-certificates && \
    update-ca-certificates

ENV INFLUXDB_VERSION=1.12.2-c1.12.2
RUN apk add --no-cache --virtual .build-deps curl gnupg tar && \
    curl -fsSLO "https://dl.influxdata.com/enterprise/releases/influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz.asc" \
         -fssLO "https://dl.influxdata.com/enterprise/releases/influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz" && \
    # Verify InfluxDB 1.X Enterprise \
    gpg --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys \
        # InfluxData Package Signing Key <support@influxdata.com> \
        24C975CBA61A024EE1B631787C3D57159FC2F927 && \
    gpg --batch --verify \
        "influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz.asc" \
        "influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz" && \
    # Install InfluxDB 1.X Enterprise \
    tar -xvf "influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz" \
        -C / --strip-components 1 --wildcards \
            'influxdb-*/usr/bin/influx' \
            'influxdb-*/usr/bin/influx_inspect' \
            'influxdb-*/usr/bin/influxd' && \
    # Cleanup \
    rm "influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz.asc" \
       "influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz" && \
    apk del .build-deps

COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
