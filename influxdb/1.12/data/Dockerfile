FROM buildpack-deps:bookworm-curl

ENV INFLUXDB_VERSION=1.12.2-c1.12.2
RUN curl -fsSLO "https://dl.influxdata.com/enterprise/releases/influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb.asc" \
         -fssLO "https://dl.influxdata.com/enterprise/releases/influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb" && \
    # Verify InfluxDB 1.X Enterprise \
    gpg --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys \
        # InfluxData Package Signing Key <support@influxdata.com> \
        24C975CBA61A024EE1B631787C3D57159FC2F927 && \
    gpg --batch --verify \
        "influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb.asc" \
        "influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb" && \
    # Install InfluxDB 1.X Enterprise \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        "/influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb" && \
    # Cleanup \
    rm -r "influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb.asc" \
          "influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb" \
          /var/lib/apt/lists/*

COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
