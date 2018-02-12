FROM buildpack-deps:jessie-curl

RUN set -ex && \
    for key in \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
    do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done

RUN wget --no-verbose https://dl.influxdata.com/influxdb/nightlies/influxdb_nightly_amd64.deb.asc && \
    wget --no-verbose https://dl.influxdata.com/influxdb/nightlies/influxdb_nightly_amd64.deb && \
    gpg --batch --verify influxdb_nightly_amd64.deb.asc influxdb_nightly_amd64.deb && \
    dpkg -i influxdb_nightly_amd64.deb && \
    rm -f influxdb_nightly_amd64.deb*
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8083 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
