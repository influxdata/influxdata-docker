FROM alpine:3.16

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache \
      ca-certificates  \
      gnupg            \
      iputils          \
      libcap           \
      lm_sensors       \
      net-snmp-tools   \
      procps           \
      su-exec          \
      tzdata           && \
    update-ca-certificates

RUN gpg --yes --batch \
      --keyserver hkps://keyserver.ubuntu.com:443 \
      --recv-keys 05CE15085FC09D18E99EFB22684A14CF2582E0C5

ENV TELEGRAF_VERSION 1.23.4

RUN set -ex && \
    apk add --no-cache --virtual .build-deps wget tar && \
    wget --no-verbose https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}_static_linux_amd64.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}_static_linux_amd64.tar.gz && \
    gpg --batch --verify telegraf-${TELEGRAF_VERSION}_static_linux_amd64.tar.gz.asc telegraf-${TELEGRAF_VERSION}_static_linux_amd64.tar.gz && \
    mkdir -p /usr/src /etc/telegraf && \
    tar -C /usr/src -xzf telegraf-${TELEGRAF_VERSION}_static_linux_amd64.tar.gz && \
    mv /usr/src/telegraf*/etc/telegraf/telegraf.conf /etc/telegraf/ && \
    mkdir /etc/telegraf/telegraf.d && \
    cp -a /usr/src/telegraf*/usr/bin/telegraf /usr/bin/ && \
    rm -rf *.tar.gz* /usr/src && \
    apk del .build-deps && \
    addgroup -S telegraf && \
    adduser -S telegraf -G telegraf && \
    chown -R telegraf:telegraf /etc/telegraf

EXPOSE 8125/udp 8092/udp 8094

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]
