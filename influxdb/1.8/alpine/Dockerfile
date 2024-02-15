FROM alpine:3.17

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache tzdata bash ca-certificates && \
    update-ca-certificates

ENV INFLUXDB_VERSION 1.8.10
RUN case "$(apk --print-arch)" in \
        x86_64)  arch=amd64 ;; \
        aarch64) arch=arm64 ;; \
        *) echo 'Unsupported architecture' && exit 1 ;; \
    esac && \
    set -ex && \
    mkdir ~/.gnupg; \
    echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
    apk add --no-cache --virtual .build-deps wget gnupg tar && \
    for key in \
        9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E ; \
    do \
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" ; \
    done && \
    case ${arch} in \
          amd64)    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz.asc && \
                    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
                    gpg --batch --verify influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz.asc influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
                    mkdir -p /usr/src && \
                    tar -C /usr/src -xzf influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
                    chmod +x /usr/src/influxdb-*/influx \
                        /usr/src/influxdb-*/influx_inspect \
                        /usr/src/influxdb-*/influx_stress \
                        /usr/src/influxdb-*/influxd && \
                    mv /usr/src/influxdb-*/influx \
                        /usr/src/influxdb-*/influx_inspect \
                        /usr/src/influxdb-*/influx_stress  \
                        /usr/src/influxdb-*/influxd \
                        /usr/bin/ && \
                    rm -rf *.tar.gz* /usr/src ;; \
          arm64)    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}_linux_arm64.tar.gz.asc && \
                    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}_linux_arm64.tar.gz && \
                    gpg --batch --verify influxdb-${INFLUXDB_VERSION}_linux_arm64.tar.gz.asc influxdb-${INFLUXDB_VERSION}_linux_arm64.tar.gz && \
                    tar xzf influxdb-${INFLUXDB_VERSION}_linux_arm64.tar.gz && \
                    cp influxdb-${INFLUXDB_VERSION}-1/usr/bin/influxd /usr/bin/influxd && \
                    rm -rf influxdb-${INFLUXDB_VERSION}*;; \
    esac && \
    gpgconf --kill all && \
    rm -rf /root/.gnupg && \
    apk del .build-deps
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
