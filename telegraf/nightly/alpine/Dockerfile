FROM alpine:3.14

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache iputils ca-certificates net-snmp-tools procps lm_sensors tzdata && \
    update-ca-certificates


ENV TELEGRAF_VERSION nightly

RUN set -ex && \
    apk add --no-cache --virtual .build-deps wget tar && \
    wget --no-verbose https://dl.influxdata.com/telegraf/nightlies/telegraf-static-${TELEGRAF_VERSION}_linux_amd64.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/telegraf/nightlies/telegraf-static-${TELEGRAF_VERSION}_linux_amd64.tar.gz && \
    mkdir -p /usr/src /etc/telegraf && \
    tar -C /usr/src -xzf telegraf-static-${TELEGRAF_VERSION}_linux_amd64.tar.gz && \
    mv /usr/src/telegraf*/etc/telegraf/telegraf.conf /etc/telegraf/ && \
    mkdir /etc/telegraf/telegraf.d && \
    cp -a /usr/src/telegraf*/usr/bin/telegraf /usr/bin/ && \
    gpgconf --kill all && \
    rm -rf *.tar.gz* /usr/src && \
    apk del .build-deps && \
    addgroup -S telegraf && \
    adduser -S telegraf -G telegraf && \
    chown -R telegraf:telegraf /etc/telegraf

EXPOSE 8125/udp 8092/udp 8094

USER telegraf

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]
