FROM buildpack-deps:trusty-curl

RUN gpg \
    --keyserver hkp://ha.pool.sks-keyservers.net \
    --recv-keys 05CE15085FC09D18E99EFB22684A14CF2582E0C5

# Note the use of `get.influxdb.com/telegraf` which differs from the
# other TICK product Dockerfiles.
ENV TELEGRAF_VERSION 0.12.0
RUN wget -q https://s3.amazonaws.com/get.influxdb.org/telegraf/telegraf_$TELEGRAF_VERSION-1_amd64.deb.asc && \
    wget -q https://s3.amazonaws.com/get.influxdb.org/telegraf/telegraf_$TELEGRAF_VERSION-1_amd64.deb && \
    gpg --batch --verify telegraf_$TELEGRAF_VERSION-1_amd64.deb.asc telegraf_$TELEGRAF_VERSION-1_amd64.deb && \
    dpkg -i telegraf_$TELEGRAF_VERSION-1_amd64.deb && \
    rm -f telegraf_$TELEGRAF_VERSION-1_amd64.deb*

EXPOSE 8125/udp 8092/udp 8094

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]
