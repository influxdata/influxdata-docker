FROM buildpack-deps:bullseye-curl

RUN set -ex && \
    mkdir ~/.gnupg; \
    echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
    for key in \
        24C975CBA61A024EE1B631787C3D57159FC2F927 ; \
    do \
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" ; \
    done

ENV INFLUXDB_VERSION 1.10.8-c1.10.8
RUN wget --no-verbose https://dl.influxdata.com/enterprise/releases/influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb.asc && \
    wget --no-verbose https://dl.influxdata.com/enterprise/releases/influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb && \
    gpg --batch --verify influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb.asc influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb && \
    dpkg -i influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb && \
    rm -f influxdb-data_${INFLUXDB_VERSION}-1_amd64.deb*
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
