FROM buildpack-deps:buster-curl

RUN groupadd -r influxdb --gid=1000 && \
    useradd -r -g influxdb --uid=1000 --home-dir=/home/influxdb --shell=/bin/bash influxdb && \
    mkdir -p /home/influxdb && \
    chown -R influxdb:influxdb /home/influxdb

# Install gosu for easy step-down from root.
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION 1.12
RUN set -eux; \
	dpkgArch="$(dpkg --print-architecture)" && \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
	export GNUPGHOME="$(mktemp -d)" && \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
	gpgconf --kill all && \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc && \
	chmod +x /usr/local/bin/gosu && \
	gosu --version && \
	gosu nobody true

# ENV INFLUXDB_VERSION 2.0.4
# TODO: Update this to use a 'real' release.
RUN set -eux && \
    ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
        amd64) ARCH='amd64';; \
        arm64) ARCH='arm64';; \
        *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    wget --no-verbose https://dl.influxdata.com/platform/nightlies/influxdb2_nightly_linux_${ARCH}.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/platform/nightlies/influxdb2_nightly_linux_${ARCH}.tar.gz && \
    export GNUPGHOME="$(mktemp -d)" && \
    echo "disable-ipv6" >> $GNUPGHOME/dirmngr.conf && \
    KEY=8C2D403D3C3BDB81A4C27C883C3E4B7317FFE40A && \
    ( \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$KEY" || \
        gpg --keyserver pgp.mit.edu --recv-keys "$KEY" || \
        gpg --keyserver keys.openpgp.org --recv-keys "$KEY" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$KEY" \
    ) && \
    gpg --batch --verify influxdb2_nightly_linux_${ARCH}.tar.gz.asc influxdb2_nightly_linux_${ARCH}.tar.gz && \
    tar xzf influxdb2_nightly_linux_${ARCH}.tar.gz && \
    cp influxdb2_nightly_linux_${ARCH}/influx* /usr/local/bin/ && \
    rm -rf "$GNUPGHOME" influxdb2.key influxdb2_nightly_${ARCH}* && \
    influxd version && \
    influx version

# Create standard directories expected by the entry-point.
RUN mkdir /docker-entrypoint-initdb.d && \
    mkdir -p /var/lib/influxdb2 && \
    chown -R influxdb:influxdb /var/lib/influxdb2 && \
    mkdir -p /etc/influxdb2 && \
    chown -R influxdb:influxdb /etc/influxdb2
VOLUME /var/lib/influxdb2 /etc/influxdb2

COPY default-config.yml /etc/defaults/influxdb2/config.yml
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]

EXPOSE 8086
ENV INFLUX_CONFIGS_PATH /etc/influxdb2/influx-configs