FROM alpine:3.22

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache ca-certificates setpriv && \
    update-ca-certificates

ENV KAPACITOR_VERSION 1.8.1

RUN set -ex && \
    mkdir ~/.gnupg; \
    echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
    apk add --no-cache --virtual .build-deps wget gnupg tar && \
    for key in \
        24C975CBA61A024EE1B631787C3D57159FC2F927 ; \
    do \
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" ; \
    done && \
    wget --no-verbose https://dl.influxdata.com/kapacitor/releases/kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/kapacitor/releases/kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz && \
    gpg --batch --verify kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz.asc kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz && \
    mkdir -p /usr/src && \
    tar -C /usr/src -xzf kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz && \
    cp -ar /usr/src/kapacitor-*/* / && \
    gpgconf --kill all && \
    rm -rf *.tar.gz* /usr/src /root/.gnupg && \
    apk del .build-deps && \
    addgroup -S kapacitor && \
    adduser -S kapacitor -G kapacitor && \
    mkdir -m 0750 -p /var/lib/kapacitor && \
    chown kapacitor:kapacitor /var/lib/kapacitor

COPY kapacitor.conf /etc/kapacitor/kapacitor.conf

EXPOSE 9092

VOLUME /var/lib/kapacitor

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["kapacitord"]
