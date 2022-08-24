FROM buildpack-deps:stretch-curl

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y bash-completion && \
    awk 'f{if(sub(/^#/,"",$0)==0){f=0}};/^# enable bash completion/{f=1};{print;}' /etc/bash.bashrc > /etc/bash.bashrc.new && \
    mv /etc/bash.bashrc.new /etc/bash.bashrc

RUN for attempt in 1 2 3 ; \
    do \
      sleep 1 && \
      gpg --yes --batch --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 && \
      break ; \
    done

ENV KAPACITOR_VERSION 1.5.9
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
      amd64) ARCH='amd64';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armhf';; \
      armel) ARCH='armel';; \
      *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    wget --no-verbose https://dl.influxdata.com/kapacitor/releases/kapacitor_${KAPACITOR_VERSION}-1_${ARCH}.deb.asc && \
    wget --no-verbose https://dl.influxdata.com/kapacitor/releases/kapacitor_${KAPACITOR_VERSION}-1_${ARCH}.deb && \
    gpg --batch --verify kapacitor_${KAPACITOR_VERSION}-1_${ARCH}.deb.asc kapacitor_${KAPACITOR_VERSION}-1_${ARCH}.deb && \
    dpkg -i kapacitor_${KAPACITOR_VERSION}-1_${ARCH}.deb && \
    rm -f kapacitor_${KAPACITOR_VERSION}-1_${ARCH}.deb*
COPY kapacitor.conf /etc/kapacitor/kapacitor.conf

EXPOSE 9092

VOLUME /var/lib/kapacitor

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["kapacitord"]
