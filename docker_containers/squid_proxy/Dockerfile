FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq squid3 apache2-utils


RUN touch /etc/squid3/passwords && \
    htpasswd -b -c -d /etc/squid3/passwords tommy iotsec && \
    chmod o+r /etc/squid3/passwords


COPY squid.conf /etc/squid3/squid.conf

RUN squid3 -N -z -F

EXPOSE 3128/tcp

CMD squid3 -NYCd 1 