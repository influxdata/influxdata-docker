FROM golang:1.15-alpine as builder
COPY . /go/src/github.com/influxdata/influxdata-docker/dockerlib
RUN set -xe; \
    apk add --no-cache git; \
    go get -d github.com/influxdata/influxdata-docker/dockerlib; \
    go install github.com/influxdata/influxdata-docker/dockerlib

FROM alpine
COPY --from=builder /go/bin/dockerlib /usr/bin/dockerlib
ENTRYPOINT ["/usr/bin/dockerlib"]
