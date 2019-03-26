FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq iperf3 && \
    apt-get install -yqq iputils-ping net-tools ethtool

COPY run.sh /

CMD ["eth0"]

ENTRYPOINT ["/run.sh"]