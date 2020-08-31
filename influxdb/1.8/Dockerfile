FROM debian:buster-slim

ENV INFLUXDB_VERSION 1.8.2

RUN set -ex; \
    fetchDeps=" \
        ca-certificates \
        gnupg \
        dirmngr \
        wget \
    "; \
    apt-get update; \
    apt-get install -y --no-install-recommends $fetchDeps; \
    \
    ARCH= && dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) ARCH='amd64';; \
        arm64) ARCH='arm64';; \
        armhf) ARCH='armhf';; \
        armel) ARCH='armel';; \
        *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac; \
    \
    for key in \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
    do \
        gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done; \
    \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_${ARCH}.deb.asc; \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_${ARCH}.deb; \
    gpg --batch --verify influxdb_${INFLUXDB_VERSION}_${ARCH}.deb.asc influxdb_${INFLUXDB_VERSION}_${ARCH}.deb; \
    dpkg -i influxdb_${INFLUXDB_VERSION}_${ARCH}.deb; \
    gpgconf --kill all; \
    rm -f "$GNUPGHOME" influxdb_${INFLUXDB_VERSION}_${ARCH}.deb*; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps; \
    rm -rf /var/lib/apt/lists/*

COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
