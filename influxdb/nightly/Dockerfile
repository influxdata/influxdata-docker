FROM buildpack-deps:jessie-curl

RUN set -ex && \
    for key in \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
    do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
        && case "${dpkgArch##*-}" in \
        amd64) ARCH='amd64';; \
        arm64) ARCH='arm64';; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    wget -q https://dl.influxdata.com/influxdb/nightlies/influxdb_nightly_$ARCH.deb.asc && \
    wget -q https://dl.influxdata.com/influxdb/nightlies/influxdb_nightly_$ARCH.deb && \
    gpg --batch --verify influxdb_nightly_$ARCH.deb.asc influxdb_nightly_$ARCH.deb && \
    dpkg -i influxdb_nightly_$ARCH.deb && \
    rm -f influxdb_nightly_$ARCH.deb*
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8083 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
