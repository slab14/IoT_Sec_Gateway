FROM ubuntu

RUN apt-get update \
    && apt-get install -yqq squid squidclient \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

#EXPOSE 3128/tcp

ENTRYPOINT ["/run.sh"]
    