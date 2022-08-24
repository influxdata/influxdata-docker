FROM debian:stretch-slim

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      curl \
      dirmngr \
      gnupg && \
    rm -rf /var/lib/apt/lists/*

RUN for attempt in 1 2 3 ; \
    do \
      sleep 1 && \
      gpg --yes --batch --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 && \
      break ; \
    done

ENV CHRONOGRAF_VERSION 1.8.10
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
      amd64) ARCH='amd64';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armhf';; \
      armel) ARCH='armel';; \
      *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    set -x && \
    curl -SLO "https://dl.influxdata.com/chronograf/releases/chronograf_${CHRONOGRAF_VERSION}_${ARCH}.deb.asc" && \
    curl -SLO "https://dl.influxdata.com/chronograf/releases/chronograf_${CHRONOGRAF_VERSION}_${ARCH}.deb" && \
    gpg --batch --verify chronograf_${CHRONOGRAF_VERSION}_${ARCH}.deb.asc chronograf_${CHRONOGRAF_VERSION}_${ARCH}.deb && \
    dpkg -i chronograf_${CHRONOGRAF_VERSION}_${ARCH}.deb && \
    rm -f chronograf_${CHRONOGRAF_VERSION}_${ARCH}.deb*

COPY LICENSE /usr/share/chronograf/LICENSE
COPY agpl-3.0.md /usr/share/chronograf/agpl-3.0.md

EXPOSE 8888

VOLUME /var/lib/chronograf

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["chronograf"]
