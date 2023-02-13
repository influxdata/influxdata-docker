FROM alpine:3.17

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache ca-certificates && \
    update-ca-certificates

ENV CHRONOGRAF_VERSION 1.8.10

RUN set -ex && \
    mkdir ~/.gnupg; \
    echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
    apk add --no-cache --virtual .build-deps wget gnupg tar && \
    for key in \
        9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E ; \
    do \
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" ; \
    done && \
    wget --no-verbose https://dl.influxdata.com/chronograf/releases/chronograf-${CHRONOGRAF_VERSION}-static_linux_amd64.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/chronograf/releases/chronograf-${CHRONOGRAF_VERSION}-static_linux_amd64.tar.gz && \
    gpg --batch --verify chronograf-${CHRONOGRAF_VERSION}-static_linux_amd64.tar.gz.asc chronograf-${CHRONOGRAF_VERSION}-static_linux_amd64.tar.gz && \
    mkdir -p /usr/src && \
    tar -C /usr/src -xzf chronograf-${CHRONOGRAF_VERSION}-static_linux_amd64.tar.gz && \
    rm -f /usr/src/chronograf-*/chronograf.conf && \
    chmod +x /usr/src/chronograf-*/* && \
    cp -a /usr/src/chronograf-*/* /usr/bin/ && \
    gpgconf --kill all && \
    rm -rf *.tar.gz* /usr/src /root/.gnupg && \
    apk del .build-deps

COPY LICENSE /usr/share/chronograf/LICENSE
COPY agpl-3.0.md /usr/share/chronograf/agpl-3.0.md

EXPOSE 8888

VOLUME /var/lib/chronograf

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["chronograf"]
