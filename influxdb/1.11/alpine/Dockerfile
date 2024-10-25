FROM alpine:3.20

RUN apk add --no-cache \
      bash \
      ca-certificates \
      tzdata && \
    update-ca-certificates

ARG TARGETARCH
ARG INFLUXDB_VERSION=1.11.7
ARG INFLUXDB_TAR=influxdb-${INFLUXDB_VERSION}-linux-${TARGETARCH}.tar.gz
ARG INFLUXDB_ASC=influxdb-${INFLUXDB_VERSION}-linux-${TARGETARCH}.tar.gz.asc
RUN apk add --no-cache --virtual .build-deps \
      curl \
      gnupg \
      tar && \
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E && \
    curl -fLO "https://dl.influxdata.com/influxdb/releases/${INFLUXDB_ASC}" && \
    curl -fLO "https://dl.influxdata.com/influxdb/releases/${INFLUXDB_TAR}" && \
    gpg --batch --verify "${INFLUXDB_ASC}" "${INFLUXDB_TAR}" && \
    tar -xf "${INFLUXDB_TAR}" -C /usr/bin \
      ./influx \
      ./influx_inspect \
      ./influxd && \
    rm -rf "${INFLUXDB_TAR}" \
           "${INFLUXDB_ASC}" && \
    apk del .build-deps
COPY influxdb.conf /etc/influxdb/influxdb.conf

RUN addgroup influxdb && \
    adduser -S -s /bin/false -h /var/lib/influxdb -G influxdb influxdb && \
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
