FROM buildpack-deps:bookworm-curl

RUN addgroup --system --gid 1500 influxdb && \
    adduser --system --uid 1500 --ingroup influxdb --home /var/lib/influxdb --shell /bin/false influxdb

ENV INFLUXDB_VERSION=1.12.3
# INFLUXDB_PR is for suffixes like -1
ENV INFLUXDB_PR=-1
ENV INFLUXDB_PV=${INFLUXDB_VERSION}${INFLUXDB_PR}
RUN set -x && \
    case "$(dpkg --print-architecture)" in \
        amd64) ARCH=amd64 ;; \
        arm64) ARCH=arm64 ;; \
        *) echo 'Unsupported Architecture' ; exit 1 ;; \
    esac && \
    curl -fsSLO "https://dl.influxdata.com/influxdb/releases/v${INFLUXDB_VERSION}/influxdb_${INFLUXDB_PV}_${ARCH}.deb.asc" \
         -fsSLO "https://dl.influxdata.com/influxdb/releases/v${INFLUXDB_VERSION}/influxdb_${INFLUXDB_PV}_${ARCH}.deb" && \
    # Verify InfluxDB 1.X OSS \
    gpg --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys \
        # InfluxData Package Signing Key <support@influxdata.com> \
        24C975CBA61A024EE1B631787C3D57159FC2F927 && \
    gpg --batch --verify \
        "influxdb_${INFLUXDB_PV}_${ARCH}.deb.asc" \
        "influxdb_${INFLUXDB_PV}_${ARCH}.deb" && \
    # Install InfluxDB 1.X OSS \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        "/influxdb_${INFLUXDB_PV}_${ARCH}.deb" && \
    # Cleanup \
    rm -r "influxdb_${INFLUXDB_PV}_${ARCH}.deb.asc" \
          "influxdb_${INFLUXDB_PV}_${ARCH}.deb" \
          /var/lib/apt/lists/*

COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086
VOLUME /var/lib/influxdb
COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
USER influxdb
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
