FROM golang:1.9.2-stretch as builder
COPY . /go/src/github.com/influxdata/influxdata-docker/dockerlib
RUN set -xe && \
    go get -d github.com/influxdata/influxdata-docker/dockerlib && \
    go install github.com/influxdata/influxdata-docker/dockerlib

FROM buildpack-deps:stretch-scm
COPY --from=builder /go/bin/dockerlib /usr/bin/dockerlib
ENTRYPOINT ["/usr/bin/dockerlib"]
