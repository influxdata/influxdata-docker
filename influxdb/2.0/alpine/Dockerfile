FROM alpine:3.14

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache tzdata bash ca-certificates gnupg run-parts && \
    update-ca-certificates

RUN addgroup -S -g 1000 influxdb && \
    adduser -S -G influxdb -u 1000 -h /home/influxdb -s /bin/sh influxdb && \
    mkdir -p /home/influxdb && \
    chown -R influxdb:influxdb /home/influxdb

# Install gosu for easy step-down from root.
# https://github.com/tianon/gosu/releases
ENV GOSU_VER 1.12
RUN set -eux; \
    ARCH="$(apk --print-arch)" && \
    case "${ARCH}" in \
        x86_64)  ARCH=amd64;; \
        aarch64) ARCH=arm64;; \
        *)       echo "Unsupported architecture: ${ARCH}"; exit 1;; \
    esac && \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VER/gosu-$ARCH"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VER/gosu-$ARCH.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

ENV INFLUXDB_VERSION 2.0.9
RUN set -eux && \
    ARCH="$(apk --print-arch)" && \
    if [ ${ARCH} = x86_64 ]; then \
        ARCH=amd64; \
    elif [ ${ARCH} = aarch64 ]; then \
        ARCH=arm64; \
    else \
        echo "Unsupported architecture: ${ARCH}" && exit 1; \
    fi && \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz && \
    export GNUPGHOME="$(mktemp -d)" && \
    echo "disable-ipv6" >> $GNUPGHOME/dirmngr.conf && \
    gpg --keyserver keys.openpgp.org --recv-keys 8C2D403D3C3BDB81A4C27C883C3E4B7317FFE40A && \
    gpg --batch --verify influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz.asc influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz && \
    tar xzf influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz && \
    cp influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}/influx* /usr/local/bin/ && \
    rm -rf "$GNUPGHOME" influxdb2.key influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}* && \
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
ENV INFLUXD_INIT_PORT 9999
ENV INFLUXD_INIT_PING_ATTEMPTS 600
ENV DOCKER_INFLUXDB_INIT_CLI_CONFIG_NAME default
