FROM buildpack-deps:jessie-curl

RUN gpg \
    --keyserver hkp://ha.pool.sks-keyservers.net \
    --recv-keys 05CE15085FC09D18E99EFB22684A14CF2582E0C5

ENV CHRONOGRAF_VERSION 1.3.0
RUN wget -q https://dl.influxdata.com/chronograf/releases/chronograf_${CHRONOGRAF_VERSION}_amd64.deb.asc && \
    wget -q https://dl.influxdata.com/chronograf/releases/chronograf_${CHRONOGRAF_VERSION}_amd64.deb && \
    gpg --batch --verify chronograf_${CHRONOGRAF_VERSION}_amd64.deb.asc chronograf_${CHRONOGRAF_VERSION}_amd64.deb && \
    dpkg -i chronograf_${CHRONOGRAF_VERSION}_amd64.deb && \
    rm -f chronograf_${CHRONOGRAF_VERSION}_amd64.deb*

COPY LICENSE /usr/share/chronograf/LICENSE
COPY agpl-3.0.md /usr/share/chronograf/agpl-3.0.md

EXPOSE 8888

VOLUME /var/lib/chronograf

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["chronograf"]
