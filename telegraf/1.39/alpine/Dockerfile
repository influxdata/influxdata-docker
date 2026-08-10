FROM alpine:3.23

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache iputils ca-certificates net-snmp-tools procps lm_sensors tzdata setpriv libcap tini && \
    update-ca-certificates

ENV TELEGRAF_VERSION 1.39.3

RUN ARCH= && \
    case "$(apk --print-arch)" in \
        x86_64) ARCH='amd64';; \
        aarch64) ARCH='arm64';; \
        *) echo "Unsupported architecture: $(apk --print-arch)"; exit 1;; \
    esac && \
    set -ex && \
    mkdir ~/.gnupg; \
    echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
    apk add --no-cache --virtual .build-deps wget gnupg tar && \
    for key in \
        24C975CBA61A024EE1B631787C3D57159FC2F927 ; \
    do \
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" ; \
    done && \
    wget --no-verbose https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}_linux_${ARCH}.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}_linux_${ARCH}.tar.gz && \
    gpg --batch --verify telegraf-${TELEGRAF_VERSION}_linux_${ARCH}.tar.gz.asc telegraf-${TELEGRAF_VERSION}_linux_${ARCH}.tar.gz && \
    mkdir -p /usr/src /etc/telegraf && \
    tar -C /usr/src -xzf telegraf-${TELEGRAF_VERSION}_linux_${ARCH}.tar.gz && \
    mv /usr/src/telegraf*/etc/telegraf/telegraf.conf /etc/telegraf/ && \
    mkdir /etc/telegraf/telegraf.d && \
    cp -a /usr/src/telegraf*/usr/bin/telegraf /usr/bin/ && \
    gpgconf --kill all && \
    rm -rf *.tar.gz* /usr/src /root/.gnupg && \
    apk del .build-deps && \
    addgroup -S telegraf && \
    adduser -S telegraf -G telegraf && \
    chown -R telegraf:telegraf /etc/telegraf && \
    # drop root from the base image default supplementary groups (bin, disk,
    # video, ...) so they are not granted to container processes at runtime
    for g in $(id -Gn root); do [ "$g" = 'root' ] || delgroup root "$g"; done

EXPOSE 8125/udp 8092/udp 8094

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD ["telegraf"]
