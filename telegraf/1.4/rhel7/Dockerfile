FROM registry.access.redhat.com/rhel7
MAINTAINER InfluxData Engineering <contact@influxdata.com>

ENV TELEGRAF_VERSION=1.4.3 \
    HOME=/var/lib/telegraf \
    SRC=/opt/telegraf/src \
    USER=telegraf \
    UID=8081

ENV SUMMARY="The plugin-driven server agent for collecting & reporting metrics" \
    DESCRIPTION="Telegraf is a plugin-drive metric collection agent for the \
the TICK stack."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      name="influxdata/telegraf" \
      vendor="InfluxData Inc." \
      version="$TELEGRAF_VERSION" \
      release="1" \
      url="https://www.influxdata.com/" \
      vcs-url="https://github.com/influxdata/influxdata-docker" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Telegraf ${INFLUXBD_VERSION}" \
      io.openshift.expose-services="" \
      io.openshift.tags="collector,metrics,telegraf"

COPY help.1 /
COPY licenses /licenses
COPY entrypoint.sh /usr/bin/

RUN REPOLIST=rhel-7-server-rpms,rhel-7-server-optional-rpms \
    INSTALL_PKGS="wget" && \
    yum -y update-minimal --disablerepo "*" --enablerepo rhel-7-server-rpms --setopt=tsflags=nodocs \
      --security --sec-severity=Important --sec-severity=Critical && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs ${INSTALL_PKGS} && \
    yum clean all && \
    wget -q https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}-static_linux_amd64.tar.gz && \
    mkdir -p ${SRC} /etc/telegraf && \
    useradd -l -u ${UID} -r -g 0 -d /opt/telegraf -s /sbin/nologin -c "${USER} user" ${USER} && \
    tar -C ${SRC} -xzf telegraf-${TELEGRAF_VERSION}-static_linux_amd64.tar.gz && \
    mv ${SRC}/telegraf/telegraf.conf /etc/telegraf/ && \
    chown -R telegraf:0 ${SRC}/telegraf/telegraf /usr/bin/entrypoint.sh && \
    chmod -R ug+x ${SRC}/telegraf/telegraf /usr/bin/entrypoint.sh && \
    cp ${SRC}/telegraf/telegraf /usr/bin/ && \
    rm -r *.tar.gz* ${SRC}

EXPOSE 8125/udp 8092/udp 8094

USER telegraf

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["telegraf"]