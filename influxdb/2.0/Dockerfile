FROM buildpack-deps:buster-curl

# TODO(jsternberg): Download key from the keyserver once it is available.
#RUN set -ex && \
#    mkdir ~/.gnupg; \
#    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 05CE15085FC09D18E99EFB22684A14CF2582E0C5
RUN set -ex && \
    mkdir ~/.gnupg; \
    wget --no-verbose https://repos.influxdata.com/influxdb2.key && \
    gpg --batch --import influxdb2.key && \
    rm -f influxdb2.key

ENV INFLUXDB_VERSION 2.0.0
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
      amd64) ARCH='amd64';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armhf';; \
      armel) ARCH='armel';; \
      *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_${ARCH}.deb.asc && \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_${ARCH}.deb && \
    gpg --batch --verify influxdb_${INFLUXDB_VERSION}_${ARCH}.deb.asc influxdb_${INFLUXDB_VERSION}_${ARCH}.deb && \
    dpkg -i influxdb_${INFLUXDB_VERSION}_${ARCH}.deb && \
    rm -f influxdb_${INFLUXDB_VERSION}_${ARCH}.deb*
COPY config.yml /etc/influxdb/config.yml
ENV INFLUXD_CONFIG_PATH /etc/influxdb

EXPOSE 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
