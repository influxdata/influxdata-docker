FROM arm64v8/buildpack-deps:trusty-curl

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends snmp && \
    rm -rf /var/lib/apt/lists/*

RUN set -ex && \
    for key in \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
    do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done

ENV TELEGRAF_VERSION 1.2.1
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
        && case "${dpkgArch##*-}" in \
        amd64) ARCH='arm64';; \
        arm64) ARCH='arm64';; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget -q https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VERSION}_$ARCH.deb.asc && \
    wget -q https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VERSION}_$ARCH.deb && \
    gpg --batch --verify telegraf_${TELEGRAF_VERSION}_$ARCH.deb.asc telegraf_${TELEGRAF_VERSION}_$ARCH.deb && \
    dpkg -i telegraf_${TELEGRAF_VERSION}_$ARCH.deb && \
    rm -f telegraf_${TELEGRAF_VERSION}_$ARCH.deb*

EXPOSE 8125/udp 8092/udp 8094

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]
