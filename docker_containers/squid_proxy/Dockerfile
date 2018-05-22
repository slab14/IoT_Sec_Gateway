FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq squid3 apache2-utils


RUN touch /etc/squid/passwords && \
    htpasswd -b -c -d /etc/squid/passwords tommy iotsec && \
    chmod o+r /etc/squid/passwords


COPY squid.conf /etc/squid/squid.conf

#RUN squid3 -N -z -F

EXPOSE 13128/tcp

CMD squid -NYCd 1 