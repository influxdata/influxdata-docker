FROM alpine:3.20

RUN apk add --no-cache \
      bash \
      ca-certificates \
      tzdata && \
    update-ca-certificates

ARG INFLUXDB_VERSION=1.11.8
RUN apk add --no-cache --virtual .build-deps \
      curl \
      gnupg \
      tar && \
    gpg --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys 24C975CBA61A024EE1B631787C3D57159FC2F927 && \
    case "$(apk --print-arch)" in \
      x86_64)  ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) exit 1 ;; \
    esac && \
    export INFLUXDB_TAR=influxdb-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz && \
    export INFLUXDB_ASC=influxdb-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz.asc && \
    curl -fLO "https://dl.influxdata.com/influxdb/releases/${INFLUXDB_TAR}" && \
    curl -fLO "https://dl.influxdata.com/influxdb/releases/${INFLUXDB_ASC}" && \
    gpg --batch --verify "${INFLUXDB_ASC}" "${INFLUXDB_TAR}" && \
    tar -xf "${INFLUXDB_TAR}" -C /usr/bin \
      influx \
      influx_inspect \
      influxd && \
    rm -rf "${INFLUXDB_TAR}" \
           "${INFLUXDB_ASC}" && \
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
