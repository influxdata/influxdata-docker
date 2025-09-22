FROM alpine:3.20

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache tzdata bash ca-certificates && \
    update-ca-certificates

ENV INFLUXDB_VERSION 1.11.8-c1.11.8
RUN set -ex && \
    apk add --no-cache --virtual .build-deps wget gnupg tar && \
    for key in \
        24C975CBA61A024EE1B631787C3D57159FC2F927 ; \
    do \
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" ; \
    done && \
    wget --no-verbose https://dl.influxdata.com/enterprise/releases/influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/enterprise/releases/influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz && \
    gpg --batch --verify influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz.asc influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz && \
    mkdir -p /usr/src && \
    tar -C /usr/src -xzf influxdb-data-${INFLUXDB_VERSION}_linux_amd64.tar.gz && \
    rm -f /usr/src/influxdb-*/influxdb.conf && \
    chmod +x /usr/src/influxdb-*/usr/bin/* && \
    cp -a /usr/src/influxdb-*/usr/bin/. /usr/bin/ && \
    gpgconf --kill all && \
    rm -rf *.tar.gz* /usr/src /root/.gnupg && \
    apk del .build-deps
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
