FROM alpine:latest

RUN apk add --update bridge-utils iptables iproute2 bash && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

COPY run.sh run.sh

ENTRYPOINT ["/run.sh"]
