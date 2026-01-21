FROM buildpack-deps:jammy-curl

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y bash-completion && \
    awk 'f{if(sub(/^#/,"",$0)==0){f=0}};/^# enable bash completion/{f=1};{print;}' /etc/bash.bashrc > /etc/bash.bashrc.new && \
    mv /etc/bash.bashrc.new /etc/bash.bashrc

RUN set -ex && \
    mkdir ~/.gnupg; \
    echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
    for key in \
        9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E ; \
    do \
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" ; \
    done

ENV KAPACITOR_VERSION 1.4.1
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
      amd64) ARCH='amd64';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armhf';; \
      armel) ARCH='armel';; \
      *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    wget --no-verbose https://dl.influxdata.com/kapacitor/releases/kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb.asc && \
    wget --no-verbose https://dl.influxdata.com/kapacitor/releases/kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb && \
    gpg --batch --verify kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb.asc kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb && \
    dpkg -i kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb && \
    rm -f kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb*
COPY kapacitor.conf /etc/kapacitor/kapacitor.conf

EXPOSE 9092

VOLUME /var/lib/kapacitor
USER kapacitor:kapacitor

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["kapacitord"]
