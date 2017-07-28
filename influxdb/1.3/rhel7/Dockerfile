FROM registry.access.redhat.com/rhel7
MAINTAINER InfluxData Engineering <contact@influxdata.com>

### Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="influxdata/influxdb" \
      vendor="InfluxData Inc." \
      version="1.3.1" \
      release="1" \
      summary="InfluxDB is the time series database for metrics and events" \
      description="InfluxDB is a time series database built from the ground up to handle high write and query loads. It is the second piece of the TICK stack. InfluxDB is meant to be used as a backing store for any use case involving large amounts of timestamped data, including DevOps monitoring, application metrics, IoT sensor data, and real-time analytics." \
      url="https://www.influxdata.com/" \
      vcs-url="https://github.com/influxdata/influxdata-docker"

ENV INFLUXDB_VERSION 1.3.1
RUN yum -y update && \
    yum -y install wget && \
    wget -q https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}.x86_64.rpm && \
    yum localinstall influxdb-${INFLUXDB_VERSION}.x86_64.rpm && \
    rm -f influxdb-${INFLUXDB_VERSION}.x86_64.rpm*

ENV INFLUXDB_VERSION 1.3.1
RUN wget -q https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}.x86_64.rpm.asc && \
    wget -q https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    gpg --batch --verify influxdb_${INFLUXDB_VERSION}_amd64.deb.asc influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    rm -f influxdb_${INFLUXDB_VERSION}_amd64.deb*
COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086

VOLUME /var/lib/influxdb

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
