FROM alpine:3.13

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache tzdata bash ca-certificates gnupg && \
    update-ca-certificates

RUN addgroup -S -g 1000 influxdb && \
    adduser -S -G influxdb -u 1000 -h /home/influxdb -s /bin/sh influxdb && \
    mkdir -p /home/influxdb && \
    chown -R influxdb:influxdb /home/influxdb

# Install gosu for easy step-down from root.
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION 1.12
RUN set -eux; \
    ARCH=$(arch) && \
    if [ ${ARCH} = x86_64 ]; then \
        ARCH=amd64; \
    elif [ ${ARCH} = aarch64 ]; then \
        ARCH=arm64; \
    else \
        echo "Unsupported architecture: ${ARCH}" && exit 1; \
    fi && \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$ARCH"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$ARCH.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

# ENV INFLUXDB_VERSION 2.0.4
# TODO: Update this to use a 'real' release.
RUN set -eux && \
    ARCH=$(arch) && \
    if [ ${ARCH} = x86_64 ]; then \
        ARCH=amd64; \
    elif [ ${ARCH} = aarch64 ]; then \
        ARCH=arm64; \
    else \
        echo "Unsupported architecture: ${ARCH}" && exit 1; \
    fi && \
    wget --no-verbose https://dl.influxdata.com/platform/nightlies/influxdb2_nightly_linux_${ARCH}.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/platform/nightlies/influxdb2_nightly_linux_${ARCH}.tar.gz && \
    export GNUPGHOME="$(mktemp -d)" && \
    wget --no-verbose https://repos.influxdata.com/influxdb2.key && \
    gpg --batch --import influxdb2.key && \
    gpg --batch --verify influxdb2_nightly_linux_${ARCH}.tar.gz.asc influxdb2_nightly_linux_${ARCH}.tar.gz && \
    tar xzf influxdb2_nightly_linux_${ARCH}.tar.gz && \
    cp influxdb2_nightly_linux_${ARCH}/influx* /usr/local/bin/ && \
    rm -rf "$GNUPGHOME" influxdb2.key influxdb2_nightly_${ARCH}* && \
    influxd version && \
    influx version

RUN mkdir /docker-entrypoint-initdb.d

RUN mkdir -p /var/lib/influxdb2 && \
    chown -R influxdb:influxdb /var/lib/influxdb2 && \
    chmod 777 /var/lib/influxdb2
VOLUME /var/lib/influxdb2

RUN mkdir -p /etc/influxdb2 && \
    chown -R influxdb:influxdb /etc/influxdb2 && \
    chmod 777 /etc/influxdb2
VOLUME /etc/influxdb2

COPY default-config.yml /etc/defaults/influxdb2/config.yml
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]

EXPOSE 8086
ENV INFLUX_CONFIGS_PATH /etc/influxdb2/influx-configs
