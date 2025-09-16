FROM alpine:3.21

RUN apk add --no-cache bash ca-certificates tzdata && \
    update-ca-certificates

ARG INFLUXDB_VERSION=1.12.2
RUN apk add --no-cache --virtual .build-deps curl gnupg tar && \
    case "$(apk --print-arch)" in \
        x86_64)  ARCH=amd64 ;; \
        aarch64) ARCH=arm64 ;; \
        *) echo 'Unsupported Architecture' ; exit 1 ;; \
    esac && \
    curl -fsSLO "https://dl.influxdata.com/influxdb/releases/v${INFLUXDB_VERSION}/influxdb-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz.asc" \
         -fsSLO "https://dl.influxdata.com/influxdb/releases/v${INFLUXDB_VERSION}/influxdb-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz" && \
    # Verify InfluxDB 1.X OSS \
    gpg --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys \
        # InfluxData Package Signing Key <support@influxdata.com> \
        9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E && \
    gpg --batch --verify \
        "influxdb-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz.asc" \
        "influxdb-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz" && \
    # Install InfluxDB 1.X OSS \
    tar -xvf "influxdb-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz" \
        -C / --strip-components 1 --wildcards \
            'influxdb-*/usr/bin/influx' \
            'influxdb-*/usr/bin/influx_inspect' \
            'influxdb-*/usr/bin/influxd' && \
    # Cleanup \
    rm "influxdb-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz.asc" \
       "influxdb-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz" && \
    apk del .build-deps

COPY influxdb.conf /etc/influxdb/influxdb.conf

RUN addgroup --system --gid 1500 influxdb && \
    adduser --system --uid 1500 --ingroup influxdb --home /var/lib/influxdb --shell /bin/false influxdb && \
    mkdir -p /var/lib/influxdb && \
    mkdir -p /var/log/influxdb && \
    chown influxdb:influxdb /var/lib/influxdb && \
    chown influxdb:influxdb /var/log/influxdb && \
    chmod 0750 /var/lib/influxdb && \
    chmod 0750 /var/log/influxdb

EXPOSE 8086
VOLUME /var/lib/influxdb
COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
USER influxdb
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
