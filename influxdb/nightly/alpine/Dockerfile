FROM alpine:3.6

RUN apk add --no-cache bash

RUN set -ex && \
    apk add --no-cache --virtual .build-deps wget gnupg tar ca-certificates && \
    update-ca-certificates && \
    for key in \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
    do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done && \
    wget --no-verbose https://dl.influxdata.com/influxdb/nightlies/influxdb-static-nightly_linux_amd64.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/influxdb/nightlies/influxdb-static-nightly_linux_amd64.tar.gz && \
    gpg --batch --verify influxdb-static-nightly_linux_amd64.tar.gz.asc influxdb-static-nightly_linux_amd64.tar.gz && \
    mkdir -p /usr/src && \
    tar -C /usr/src -xzf influxdb-static-nightly_linux_amd64.tar.gz && \
    rm -f /usr/src/influxdb-*/influxdb.conf && \
    chmod +x /usr/src/influxdb-*/* && \
    cp -a /usr/src/influxdb-*/* /usr/bin/ && \
    rm -rf *.tar.gz* /usr/src /root/.gnupg && \
    apk del .build-deps
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8083 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
