FROM buildpack-deps:buster-curl

RUN groupadd -r influxdb --gid=999 && \
    useradd -r -g influxdb --uid=999 --home-dir=/home/influxdb --shell=/bin/bash influxdb && \
    mkdir -p /home/influxdb && \
    chown -R influxdb:influxdb /home/influxdb

# Install gosu for easy step-down from root.
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION 1.12
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

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
RUN set -eux && \
    mkdir ~/.gnupg; \
    wget --no-verbose https://repos.influxdata.com/influxdb2.key && \
    gpg --batch --import influxdb2.key && \
    rm -f influxdb2.key

# ENV INFLUXDB_VERSION 2.0.4
# TODO: Update this to use a 'real' release.
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
        amd64) ARCH='amd64';; \
        arm64) ARCH='arm64';; \
        *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    wget --no-verbose https://dl.influxdata.com/platform/nightlies/influxdb2_nightly_linux_${ARCH}.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/platform/nightlies/influxdb2_nightly_linux_${ARCH}.tar.gz && \
    gpg --batch --verify influxdb2_nightly_linux_${ARCH}.tar.gz.asc influxdb2_nightly_linux_${ARCH}.tar.gz && \
    tar xzf influxdb2_nightly_linux_${ARCH}.tar.gz && \
    cp influxdb2_nightly_linux_${ARCH}/influx* /usr/local/bin/ && \
    rm -rf influxdb2_nightly_${ARCH}*

RUN mkdir /docker-entrypoint-initdb.d

RUN mkdir -p /var/lib/influxdb2 && \
    chown -R influxdb:influxdb /var/lib/influxdb2 && \
    chmod 777 /var/lib/influxdb2
VOLUME /var/lib/influxdb2

RUN mkdir -p /etc/influxdb2 && \
    chown -R influxdb:influxdb /etc/influxdb2 && \
    chmod 777 /etc/influxdb2
VOLUME /etc/influxdb2

COPY default-config.yml /etc/defaults/influxdb2/config.yml
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]

EXPOSE 8086
ENV INFLUX_CONFIGS_PATH /etc/influxdb2/influx-configs
