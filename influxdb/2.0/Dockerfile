FROM buildpack-deps:buster-curl

# RUN set -ex && \
#     mkdir ~/.gnupg && \
#     chmod go-rwx ~/.gnupg; \
#     echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
#     for key in \
#         05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
#     do \
#         gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
#         gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
#         gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
#     done
RUN set -ex && \
    mkdir ~/.gnupg; \
    wget --no-verbose https://repos.influxdata.com/influxdb2.key && \
    gpg --batch --import influxdb2.key && \
    rm -f influxdb2.key

# ENV INFLUXDB_VERSION 2.0.4
# RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
#     case "${dpkgArch##*-}" in \
#         amd64) ARCH='amd64';; \
#         arm64) ARCH='arm64';; \
#         *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
#     esac && \
#     wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb2_${INFLUXDB_VERSION}_${ARCH}.deb.asc && \
#     wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb2_${INFLUXDB_VERSION}_${ARCH}.deb && \
#     gpg --batch --verify influxdb2_${INFLUXDB_VERSION}_${ARCH}.deb.asc influxdb2_${INFLUXDB_VERSION}_${ARCH}.deb && \
#     dpkg -i influxdb2_${INFLUXDB_VERSION}_${ARCH}.deb && \
#     rm -f influxdb2_${INFLUXDB_VERSION}_${ARCH}.deb*
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
        amd64) ARCH='amd64';; \
        arm64) ARCH='arm64';; \
        *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    wget --no-verbose https://dl.influxdata.com/platform/nightlies/influxdb2_nightly_${ARCH}.deb.asc && \
    wget --no-verbose https://dl.influxdata.com/platform/nightlies/influxdb2_nightly_${ARCH}.deb && \
    gpg --batch --verify influxdb2_nightly_${ARCH}.deb.asc influxdb2_nightly_${ARCH}.deb && \
    dpkg -i influxdb2_nightly_${ARCH}.deb && \
    rm -f influxdb2_nightly_${ARCH}.deb*

EXPOSE 8086
VOLUME /etc/influxdb2 /var/lib/influxdb2
ENV INFLUX_CONFIGS_PATH /etc/influxdb2/influx-configs

COPY default-config.yml /etc/defaults/influxdb2/config.yml
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
