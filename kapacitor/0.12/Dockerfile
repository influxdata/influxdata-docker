FROM buildpack-deps:jessie-curl

RUN gpg \
    --keyserver hkp://ha.pool.sks-keyservers.net \
    --recv-keys 05CE15085FC09D18E99EFB22684A14CF2582E0C5

ENV KAPACITOR_VERSION 0.12.0
RUN wget -q https://s3.amazonaws.com/kapacitor/kapacitor_$KAPACITOR_VERSION-1_amd64.deb.asc && \
    wget -q https://s3.amazonaws.com/kapacitor/kapacitor_$KAPACITOR_VERSION-1_amd64.deb && \
    gpg --batch --verify kapacitor_$KAPACITOR_VERSION-1_amd64.deb.asc kapacitor_$KAPACITOR_VERSION-1_amd64.deb && \
    dpkg -i kapacitor_$KAPACITOR_VERSION-1_amd64.deb && \
    rm -f kapacitor_$KAPACITOR_VERSION-1_amd64.deb*

EXPOSE 9092

VOLUME /var/lib/kapacitor

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["kapacitord"]
