FROM buildpack-deps:jessie-curl

RUN gpg \
    --keyserver hkp://ha.pool.sks-keyservers.net \
    --recv-keys 05CE15085FC09D18E99EFB22684A14CF2582E0C5

RUN wget -q https://dl.influxdata.com/influxdb/nightlies/influxdb_nightly_amd64.deb.asc && \
    wget -q https://dl.influxdata.com/influxdb/nightlies/influxdb_nightly_amd64.deb && \
    gpg --batch --verify influxdb_nightly_amd64.deb.asc influxdb_nightly_amd64.deb && \
    dpkg -i influxdb_nightly_amd64.deb && \
    rm -f influxdb_nightly_amd64.deb*
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8083 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
