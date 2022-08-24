FROM alpine:3.16

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache ca-certificates gnupg && \
    update-ca-certificates

RUN for attempt in 1 2 3 ; \
    do \
      sleep 1 && \
      gpg --yes --batch --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 && \
      break ; \
    done

ENV KAPACITOR_VERSION 1.6.5

RUN set -ex && \
    apk add --no-cache --virtual .build-deps wget tar && \
    wget --no-verbose https://dl.influxdata.com/kapacitor/releases/kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/kapacitor/releases/kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz && \
    gpg --batch --verify kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz.asc kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz && \
    mkdir -p /usr/src && \
    tar -C /usr/src -xzf kapacitor-${KAPACITOR_VERSION}_linux_amd64.tar.gz && \
    cp -ar /usr/src/kapacitor-*/* / && \
    rm -rf *.tar.gz* /usr/src && \
    apk del .build-deps
COPY kapacitor.conf /etc/kapacitor/kapacitor.conf
EXPOSE 9092

VOLUME /var/lib/kapacitor

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["kapacitord"]
