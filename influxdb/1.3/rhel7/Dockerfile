FROM registry.access.redhat.com/rhel7
MAINTAINER InfluxData Engineering <contact@influxdata.com>

### Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="influxdata/influxdb" \
      vendor="InfluxData Inc." \
      version="1.3.1" \
      release="1" \
      summary="InfluxDB is the time series database for metrics and events" \
      description="InfluxDB is a time series database built from the ground up to handle high write and query loads. It is the second piece of the TICK stack. InfluxDB is meant to be used as a backing store for any use case involving large amounts of timestamped data, including DevOps monitoring, application metrics, IoT sensor data, and real-time analytics." \
### Required labels above - recommended below
      url="https://www.influxdata.com/" \
      vcs-url="https://github.com/influxdata/influxdata-docker"

### Atomic Help File - Write in Markdown, it will be converted to man format at build time.
### https://github.com/projectatomic/container-best-practices/blob/master/creating/help.adoc
COPY help.md /tmp/

### add licenses to this directory
COPY licenses /licenses

### Add necessary Red Hat repos here
RUN REPOLIST=rhel-7-server-rpms,rhel-7-server-optional-rpms \
### Add your package needs here
    INSTALL_PKGS="golang-github-cpuguy83-go-md2man" && \
    yum -y update-minimal --disablerepo "*" --enablerepo rhel-7-server-rpms --setopt=tsflags=nodocs \
      --security --sec-severity=Important --sec-severity=Critical && \
    yum -y install https://dl.influxdata.com/influxdb/releases/influxdb-1.3.1.x86_64.rpm && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs ${INSTALL_PKGS} && \
### help file markdown to man conversion
    go-md2man -in /tmp/help.md -out /help.1 && \
    yum clean all

### Setup user for build execution and application runtime
ENV INFLUXDB_ROOT=/opt/influxdb \
    USER_NAME=influxdb \
    USER_UID=10001
ENV INFLUXDB_HOME=${INFLUXDB_ROOT}/src  PATH=$PATH:${INFLUXDB_ROOT}/bin
RUN mkdir -p ${INFLUXDB_HOME}
COPY bin/ ${INFLUXDB_ROOT}/bin/
# RUN chmod -R ug+x ${INFLUXDB_ROOT}/bin && sync && \
#     useradd -l -u ${USER_UID} -r -g 0 -d ${INFLUXDB_ROOT} -s /sbin/nologin -c "${USER_NAME} user" ${USER_NAME} && \
#     chown -R ${USER_UID}:0 ${INFLUXDB_ROOT} && \
#     chmod -R g=u ${INFLUXDB_ROOT}

####### Add app-specific needs below. #######
### Containers should NOT run as root as a good practice
USER 10001
WORKDIR ${INFLUXDB_ROOT}
VOLUME ${INFLUXDB_ROOT}/logs ${INFLUXDB_ROOT}/data
ENTRYPOINT ["/opt/influxdb/bin/entrypoint.sh"]
CMD ["influxd"]