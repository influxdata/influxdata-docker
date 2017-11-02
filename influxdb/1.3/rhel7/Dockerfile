FROM registry.access.redhat.com/rhel7
MAINTAINER InfluxData Engineering <contact@influxdata.com>

ENV INFLUXDB_VERSION=1.3.7 \
    HOME=/var/lib/influxdb \
    SRC=/opt/influxdb/src \
    USER=influxdb \
    UID=8086

ENV SUMMARY="InfluxDB is the time series database for metrics and events" \
    DESCRIPTION="InfluxDB is a time series database built from the ground up \
to handle high write and query loads. It is the second piece of the TICK stack. \
InfluxDB is meant to be used as a backing store for any use case involving \
large amounts of timestamped data, including DevOps monitoring, application \
metrics, IoT sensor data, and real-time analytics."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      name="influxdata/influxdb" \
      vendor="InfluxData Inc." \
      version="$INFLUXDB_VERSION" \
      release="1" \
      url="https://www.influxdata.com/" \
      vcs-url="https://github.com/influxdata/influxdata-docker" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="InfluxDB $INFLUXBD_VERSION" \
      io.openshift.expose-services="8086:influxdb" \
      io.openshift.tags="database,time-series,influxdb"

COPY help.1 /
COPY licenses /licenses
COPY entrypoint.sh /usr/bin/

RUN REPOLIST=rhel-7-server-rpms,rhel-7-server-optional-rpms \
    INSTALL_PKGS="wget" && \
    yum -y update-minimal --disablerepo "*" --enablerepo rhel-7-server-rpms --setopt=tsflags=nodocs \
      --security --sec-severity=Important --sec-severity=Critical && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs ${INSTALL_PKGS} && \
    yum clean all && \
    wget -q https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
    mkdir -p ${SRC} && \
    useradd -l -u ${UID} -r -g 0 -d /opt/influxdb -s /sbin/nologin -c "${USER} user" ${USER} && \
    mkdir -p ${HOME} && chown influxdb:0 ${HOME} && chmod -R ug+rwx ${HOME} && \
    tar -C ${SRC} -xzf influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
    rm -r ${SRC}/influxdb-*/influxdb.conf ${SRC}/influxdb-*/usr && \
    chown -R influxdb:0 ${SRC}/influxdb-*/* /usr/bin/entrypoint.sh && \
    chmod -R ug+x ${SRC}/influxdb-*/* /usr/bin/entrypoint.sh && \
    cp ${SRC}/influxdb-*/* /usr/bin/ && \
    rm -r *.tar.gz* ${SRC}
COPY influxdb.conf /etc/influxdb/influxdb.conf

VOLUME /var/lib/influxdb

EXPOSE 8086

USER influxdb

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["influxd"]