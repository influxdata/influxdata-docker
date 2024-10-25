FROM buildpack-deps:bookworm-curl

ARG TARGETARCH
ARG INFLUXDB_VERSION=1.11.7
ARG INFLUXDB_DEB=influxdb-${INFLUXDB_VERSION}-${TARGETARCH}.deb
ARG INFLUXDB_ASC=influxdb-${INFLUXDB_VERSION}-${TARGETARCH}.deb.asc
RUN gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    curl -fLO "https://dl.influxdata.com/influxdb/releases/${INFLUXDB_DEB}" && \
    curl -fLO "https://dl.influxdata.com/influxdb/releases/${INFLUXDB_ASC}" && \
    gpg --batch --verify "${INFLUXDB_ASC}" "${INFLUXDB_DEB}" && \
    apt-get install -y "./${INFLUXDB_DEB}" && \
    rm -rf "${INFLUXDB_PKG}" \
           "${INFLUXDB_ASC}" \
	   /var/lib/apt/lists/*
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086
VOLUME /var/lib/influxdb
COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
USER influxdb
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
