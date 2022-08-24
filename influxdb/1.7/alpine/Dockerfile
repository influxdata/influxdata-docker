FROM alpine:3.14

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache tzdata bash ca-certificates gnupg && \
    update-ca-certificates

RUN for attempt in 1 2 3 ; \
    do \
      sleep 1 && \
      gpg --yes --batch --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 && \
      break ; \
    done

ENV INFLUXDB_VERSION 1.7.11
RUN set -ex && \
    apk add --no-cache --virtual .build-deps wget tar && \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
    gpg --batch --verify influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz.asc influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
    mkdir -p /usr/src && \
    tar -C /usr/src -xzf influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
    chmod +x /usr/src/influxdb-*/influx \
             /usr/src/influxdb-*/influx_inspect \
             /usr/src/influxdb-*/influx_stress \
             /usr/src/influxdb-*/influx_tsm \
             /usr/src/influxdb-*/influxd &&\
    cp -a /usr/src/influxdb-*/influx \
          /usr/src/influxdb-*/influx_inspect \
          /usr/src/influxdb-*/influx_stress  \
          /usr/src/influxdb-*/influx_tsm \
          /usr/src/influxdb-*/influxd \
          /usr/bin/ &&\
    rm -rf *.tar.gz* /usr/src && \
    apk del .build-deps
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
