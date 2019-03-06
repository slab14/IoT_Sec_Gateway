FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq iperf3

COPY run.sh /

CMD ["eth0"]

ENTRYPOINT ["/run.sh"]