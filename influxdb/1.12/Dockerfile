FROM buildpack-deps:bookworm-curl

RUN addgroup --system --gid 1500 influxdb && \
    adduser --system --uid 1500 --ingroup influxdb --home /var/lib/influxdb --shell /bin/false influxdb

ARG INFLUXDB_VERSION=1.12.2
RUN set -x && \
    case "$(dpkg --print-architecture)" in \
        amd64) ARCH=amd64 ;; \
        arm64) ARCH=arm64 ;; \
        *) echo 'Unsupported Architecture' ; exit 1 ;; \
    esac && \
    curl -fsSLO "https://dl.influxdata.com/influxdb/releases/v${INFLUXDB_VERSION}/influxdb_${INFLUXDB_VERSION}-1_${ARCH}.deb.asc" \
         -fsSLO "https://dl.influxdata.com/influxdb/releases/v${INFLUXDB_VERSION}/influxdb_${INFLUXDB_VERSION}-1_${ARCH}.deb" && \
    # Verify InfluxDB 1.X OSS \
    gpg --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys \
        # InfluxData Package Signing Key <support@influxdata.com> \
        9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E && \
    gpg --batch --verify \
        "influxdb_${INFLUXDB_VERSION}-1_${ARCH}.deb.asc" \
        "influxdb_${INFLUXDB_VERSION}-1_${ARCH}.deb" && \
    # Install InfluxDB 1.X OSS \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        "/influxdb_${INFLUXDB_VERSION}-1_${ARCH}.deb" && \
    # Cleanup \
    rm -r "influxdb_${INFLUXDB_VERSION}-1_${ARCH}.deb.asc" \
          "influxdb_${INFLUXDB_VERSION}-1_${ARCH}.deb" \
          /var/lib/apt/lists/*

COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086
VOLUME /var/lib/influxdb
COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
USER influxdb
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
