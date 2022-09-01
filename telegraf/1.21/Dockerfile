FROM buildpack-deps:bullseye-curl

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update                        && \
    apt-get install                       \
      --yes --no-install-recommends       \
        iputils-ping                      \
        libcap2-bin                       \
        lm-sensors                        \
        procps                            \
        snmp                              && \
    rm -rf /var/lib/apt/lists

RUN gpg --yes --batch \
      --keyserver hkps://keyserver.ubuntu.com:443 \
      --recv-keys 05CE15085FC09D18E99EFB22684A14CF2582E0C5

ENV TELEGRAF_VERSION 1.21.4
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
      amd64) ARCH='amd64';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armhf';; \
      armel) ARCH='armel';; \
      *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    wget --no-verbose https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb.asc && \
    wget --no-verbose https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb && \
    gpg --batch --verify telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb.asc telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb && \
    dpkg -i telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb && \
    rm -f telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb*

EXPOSE 8125/udp 8092/udp 8094

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]
