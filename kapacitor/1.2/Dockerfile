FROM buildpack-deps:stretch-curl

RUN set -ex && \
    for key in \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
    do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done

ENV KAPACITOR_VERSION 1.2.1
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
      amd64) ARCH='amd64';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armhf';; \
      armel) ARCH='armel';; \
      *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    wget -q https://dl.influxdata.com/kapacitor/releases/kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb.asc && \
    wget -q https://dl.influxdata.com/kapacitor/releases/kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb && \
    gpg --batch --verify kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb.asc kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb && \
    dpkg -i kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb && \
    rm -f kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb*
COPY kapacitor.conf /etc/kapacitor/kapacitor.conf

EXPOSE 9092

VOLUME /var/lib/kapacitor

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["kapacitord"]
