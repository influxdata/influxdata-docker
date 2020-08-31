FROM debian:buster-slim

ENV INFLUXDB_VERSION 1.7.10-c1.7.10

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
    wget --no-verbose https://dl.influxdata.com/enterprise/releases/influxdb-meta_${INFLUXDB_VERSION}_${ARCH}.deb.asc; \
    wget --no-verbose https://dl.influxdata.com/enterprise/releases/influxdb-meta_${INFLUXDB_VERSION}_${ARCH}.deb; \
    gpg --batch --verify influxdb-meta_${INFLUXDB_VERSION}_${ARCH}.deb.asc influxdb-meta_${INFLUXDB_VERSION}_${ARCH}.deb; \
    dpkg -i influxdb-meta_${INFLUXDB_VERSION}_${ARCH}.deb; \
    gpgconf --kill all; \
    rm -f "$GNUPGHOME" influxdb-meta_${INFLUXDB_VERSION}_${ARCH}.deb*; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps; \
    rm -rf /var/lib/apt/lists/*

COPY influxdb-meta.conf /etc/influxdb/influxdb-meta.conf

EXPOSE 8091

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd-meta"]
