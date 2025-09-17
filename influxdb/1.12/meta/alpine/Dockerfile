FROM alpine:3.21

RUN apk add --no-cache tzdata bash ca-certificates && \
    update-ca-certificates

ENV INFLUXDB_VERSION=1.12.2-c1.12.2
RUN apk add --no-cache --virtual .build-deps curl gnupg tar && \
    curl -fsSLO "https://dl.influxdata.com/enterprise/releases/influxdb-meta-${INFLUXDB_VERSION}_linux_amd64.tar.gz.asc" \
         -fssLO "https://dl.influxdata.com/enterprise/releases/influxdb-meta-${INFLUXDB_VERSION}_linux_amd64.tar.gz" && \
    # Verify InfluxDB 1.X Enterprise \
    gpg --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys \
        # InfluxData Package Signing Key <support@influxdata.com> \
        24C975CBA61A024EE1B631787C3D57159FC2F927 && \
    gpg --batch --verify \
        "influxdb-meta-${INFLUXDB_VERSION}_linux_amd64.tar.gz.asc" \
        "influxdb-meta-${INFLUXDB_VERSION}_linux_amd64.tar.gz" && \
    # Install InfluxDB 1.X Enterprise \
    tar -xvf "influxdb-meta-${INFLUXDB_VERSION}_linux_amd64.tar.gz" \
        -C / --strip-components 1 --wildcards \
            'influxdb-*/usr/bin/influxd-ctl' \
            'influxdb-*/usr/bin/influxd-meta' && \
    # Cleanup \
    rm "influxdb-meta-${INFLUXDB_VERSION}_linux_amd64.tar.gz.asc" \
       "influxdb-meta-${INFLUXDB_VERSION}_linux_amd64.tar.gz" && \
    apk del .build-deps

COPY influxdb-meta.conf /etc/influxdb/influxdb-meta.conf

EXPOSE 8091

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd-meta"]
