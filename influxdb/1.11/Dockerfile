FROM buildpack-deps:bookworm-curl

RUN addgroup --system --gid 1500 influxdb && \
    adduser --system --uid 1500 --ingroup influxdb --home /var/lib/influxdb --shell /bin/false influxdb

ARG INFLUXDB_VERSION=1.11.8
RUN gpg --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys 24C975CBA61A024EE1B631787C3D57159FC2F927 && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    case "$(dpkg --print-architecture)" in \
      *amd64) ARCH=amd64 ;; \
      *arm64) ARCH=arm64 ;; \
      *) exit 1 ;; \
    esac && \
    export INFLUXDB_DEB=influxdb-${INFLUXDB_VERSION}-${ARCH}.deb && \
    export INFLUXDB_ASC=influxdb-${INFLUXDB_VERSION}-${ARCH}.deb.asc && \
    curl -fLO "https://dl.influxdata.com/influxdb/releases/${INFLUXDB_DEB}" && \
    curl -fLO "https://dl.influxdata.com/influxdb/releases/${INFLUXDB_ASC}" && \
    gpg --batch --verify "${INFLUXDB_ASC}" "${INFLUXDB_DEB}" && \
    apt-get install -y "./${INFLUXDB_DEB}" && \
    rm -rf "${INFLUXDB_DEB}" \
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
