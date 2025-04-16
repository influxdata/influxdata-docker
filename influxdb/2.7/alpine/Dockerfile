FROM alpine:3.21

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      gnupg \
      run-parts \
      su-exec \
      tzdata && \
    update-ca-certificates

# Install dasel for configuration parsing
RUN case "$(apk --print-arch)" in \
      x86_64)  arch=amd64 ;; \
      aarch64) arch=arm64 ;; \
      *) echo 'Unsupported architecture' && exit 1 ;; \
    esac && \
    curl -fL "https://github.com/TomWright/dasel/releases/download/v2.4.1/dasel_linux_${arch}.gz" | gzip -d > /usr/local/bin/dasel && \
    case ${arch} in \
      amd64) echo '8e9fb0aa24e35774fab792005f05f9df141c22ec0a7436c7329a932582a10200  /usr/local/bin/dasel' ;; \
      arm64) echo '535f0f4c6362aa4b773664f7cfdb52d86f2723eac52a1aca6dfc6a69e2341c17  /usr/local/bin/dasel' ;; \
    esac | sha256sum -c - && \
    chmod +x /usr/local/bin/dasel && \
    dasel --version

RUN addgroup -S -g 1000 influxdb && \
    adduser -S -G influxdb -u 1000 -h /home/influxdb -s /bin/sh influxdb && \
    mkdir -p /home/influxdb && \
    chown -R influxdb:influxdb /home/influxdb

# Install the infuxd server
ENV INFLUXDB_VERSION 2.7.11
RUN case "$(apk --print-arch)" in \
      x86_64)  arch=amd64 ;; \
      aarch64) arch=arm64 ;; \
      *) echo 'Unsupported architecture' && exit 1 ;; \
    esac && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys \
      # InfluxData Package Signing Key <support@influxdata.com>
      9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E &&\
    curl -fLO "https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}_linux_${arch}.tar.gz" \
         -fLO "https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}_linux_${arch}.tar.gz.asc" && \
    gpg --batch --verify "influxdb2-${INFLUXDB_VERSION}_linux_${arch}.tar.gz.asc" \
                         "influxdb2-${INFLUXDB_VERSION}_linux_${arch}.tar.gz" && \
    tar xzf "influxdb2-${INFLUXDB_VERSION}_linux_${arch}.tar.gz" && \
    cp "influxdb2-${INFLUXDB_VERSION}/usr/bin/influxd" /usr/local/bin/influxd && \
    rm -rf "influxdb2-${INFLUXDB_VERSION}_linux_${arch}.tar.gz" \
           "influxdb2-${INFLUXDB_VERSION}_linux_${arch}.tar.gz.asc" \
           "influxdb2-${INFLUXDB_VERSION}" && \
    influxd version

# Install the influx CLI
ENV INFLUX_CLI_VERSION 2.7.5
RUN case "$(apk --print-arch)" in \
      x86_64)  arch=amd64 ;; \
      aarch64) arch=arm64 ;; \
      *) echo 'Unsupported architecture' && exit 1 ;; \
    esac && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys \
      # InfluxData Package Signing Key <support@influxdata.com>
      9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E && \
    curl -fLO "https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz" \
         -fLO "https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz.asc" && \
    gpg --batch --verify "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz.asc" \
                         "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz" && \
    tar xzf "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz" && \
    cp influx /usr/local/bin/influx && \
    rm -rf "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}" \
           "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz" \
           "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz.asc" && \
    influx version

# Create standard directories expected by the entry-point.
RUN mkdir /docker-entrypoint-initdb.d && \
    mkdir -p /var/lib/influxdb2 && \
    chown -R influxdb:influxdb /var/lib/influxdb2 && \
    mkdir -p /etc/influxdb2 && \
    chown -R influxdb:influxdb /etc/influxdb2
VOLUME /var/lib/influxdb2 /etc/influxdb2

COPY default-config.yml /etc/defaults/influxdb2/config.yml
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]

EXPOSE 8086

ENV INFLUX_CONFIGS_PATH /etc/influxdb2/influx-configs
ENV INFLUXD_INIT_PORT 9999
ENV INFLUXD_INIT_PING_ATTEMPTS 600
ENV DOCKER_INFLUXDB_INIT_CLI_CONFIG_NAME default
