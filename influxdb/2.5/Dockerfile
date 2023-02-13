FROM debian:bullseye-slim

RUN export DEBIAN_FRONTEND=noninteractive && \
    # install dependencies \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg && \
    # cleanup apt \
    apt-get clean && \
    rm -rf /var/lib/apt/lists \
           /var/cache/apt/archives

RUN gpg --batch --keyserver keyserver.ubuntu.com --recv-keys \
      # Tianon Gravi <tianon@tianon.xyz> (gosu)
      B42F6819007F00F88E364FD4036A9C25BF357DD4 \
      # InfluxData Package Signing Key <support@influxdata.com>
      9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E

# Install yq for configuration parsing
RUN case "$(uname -m)" in \
      x86_64)  arch=amd64 ;; \
      aarch64) arch=arm64 ;; \
      *) echo 'Unsupported architecture' && exit 1 ;; \
    esac && \
    curl -o /usr/local/bin/yq -sSL "https://github.com/mikefarah/yq/releases/download/v4.30.8/yq_linux_${arch}" && \
    case ${arch} in \
      amd64) echo '6c911103e0dcc54e2ba07e767d2d62bcfc77452b39ebaee45b1c46f062f4fd26 /usr/local/bin/yq' ;; \
      arm64) echo '95092e8b5332890c46689679b5e4360d96873c025ad8bafd961688f28ea434c7 /usr/local/bin/yq' ;; \
    esac | sha256sum -c - && \
    chmod +x /usr/local/bin/yq && \
    yq --version

RUN groupadd -r influxdb --gid=1000 && \
    useradd -r -g influxdb --uid=1000 --create-home --home-dir=/home/influxdb --shell=/bin/bash influxdb

# Install gosu for easy step-down from root
ENV GOSU_VER 1.12
RUN case "$(uname -m)" in \
      x86_64)  arch=amd64 ;; \
      aarch64) arch=arm64 ;; \
      *) echo 'Unsupported architecture' && exit 1 ;; \
    esac && \
    curl -o /usr/local/bin/gosu     -sSL "https://github.com/tianon/gosu/releases/download/$GOSU_VER/gosu-${arch}" \
         -o /usr/local/bin/gosu.asc -sSL "https://github.com/tianon/gosu/releases/download/$GOSU_VER/gosu-${arch}.asc" && \
    gpg --batch --verify /usr/local/bin/gosu.asc \
                         /usr/local/bin/gosu && \
    rm -rf /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    gosu --version && \
    gosu nobody true

# Install the influxd server
ENV INFLUXDB_VERSION 2.5.1
RUN case "$(uname -m)" in \
      x86_64)  arch=amd64 ;; \
      aarch64) arch=arm64 ;; \
      *) echo 'Unsupported architecture' && exit 1 ;; \
    esac && \
    curl -sSLO "https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}-linux-${arch}.tar.gz" \
         -sSLO "https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}-linux-${arch}.tar.gz.asc" && \
    gpg --batch --verify "influxdb2-${INFLUXDB_VERSION}-linux-${arch}.tar.gz.asc" \
                         "influxdb2-${INFLUXDB_VERSION}-linux-${arch}.tar.gz" && \
    tar xzf "influxdb2-${INFLUXDB_VERSION}-linux-${arch}.tar.gz" && \
    cp "influxdb2_linux_${arch}/influxd" /usr/local/bin/influxd && \
    rm -rf "influxdb2-${INFLUXDB_VERSION}-linux-${arch}.tar.gz" \
           "influxdb2-${INFLUXDB_VERSION}-linux-${arch}.tar.gz.asc" \
           "influxdb2_linux_${arch}" && \
    influxd version

# Install the influx CLI
ENV INFLUX_CLI_VERSION 2.5.0
RUN case "$(uname -m)" in \
      x86_64)  arch=amd64 ;; \
      aarch64) arch=arm64 ;; \
      *) echo 'Unsupported architecture' && exit 1 ;; \
    esac && \
    curl -sSLO "https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz" \
         -sSLO "https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz.asc" && \
    gpg --batch --verify "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz.asc" \
                         "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz" && \
    tar xzf "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}.tar.gz" && \
    cp "influxdb2-client-${INFLUX_CLI_VERSION}-linux-${arch}/influx" /usr/local/bin/influx && \
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
