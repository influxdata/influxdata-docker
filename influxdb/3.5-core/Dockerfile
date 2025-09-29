FROM ubuntu:24.04

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        gettext-base \
        gnupg \
        libssl3 && \
    rm -rf /var/lib/apt/lists*

RUN groupadd --gid 1500 influxdb3 && \
    useradd  --uid 1500 --gid influxdb3 --shell /bin/bash --create-home influxdb3 && \
    mkdir -p /var/lib/influxdb3 \
             /usr/lib/influxdb3 \
             /plugins

ENV INFLUXDB_VERSION=3.4.2
RUN case "$(dpkg --print-architecture)" in \
        amd64) ARCH=amd64 ;; \
        arm64) ARCH=arm64 ;; \
        *) echo 'Unsupported Architecture' ; exit 1 ;; \
    esac && \
    curl -fsSLO "https://dl.influxdata.com/influxdb/releases/influxdb3-core-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz.asc" \
         -fsSLO "https://dl.influxdata.com/influxdb/releases/influxdb3-core-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz" && \
    # Verify InfluxDB3 Core \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys \
        # InfluxData Package Signing Key <support@influxdata.com> \
        24C975CBA61A024EE1B631787C3D57159FC2F927 && \
    gpg --batch --verify \
        "influxdb3-core-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz.asc" \
        "influxdb3-core-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz" && \
    # Install InfluxDB3 Core \
    tar --strip-components 1 -C /usr/lib/influxdb3 -xvf "influxdb3-core-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz" && \
    mv /usr/lib/influxdb3/influxdb3 /usr/bin/influxdb3 && \
    chown -R influxdb3:influxdb3 /var/lib/influxdb3 /plugins && \
    chown -R root:root /usr/lib/influxdb3 && \
    # Cleanup \
    rm  "influxdb3-core-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz.asc" \
        "influxdb3-core-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz"

COPY entrypoint.sh /usr/bin/entrypoint.sh

USER influxdb3
RUN mkdir ~/.influxdb3

ENV INFLUXDB3_PLUGIN_DIR=/plugins
ENV INFLUXDB3_DATA_DIR=/home/influxdb3/.influxdb3
ENV INFLUXDB_IOX_DB_DIR=/var/lib/influxdb3
ENV LOG_FILTER=info

EXPOSE 8181

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["influxdb3", "serve"]
