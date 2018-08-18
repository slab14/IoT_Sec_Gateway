FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq squid3 apache2-utils ethtool && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    touch /etc/squid/passwords

COPY squid.conf /etc/squid/squid.conf

COPY run.sh update_password.sh remove_password.sh add_password.sh genPwdFile.sh /

EXPOSE 13128/tcp

CMD ["squid", "-NYCd", "1"]

ENTRYPOINT ["/run.sh"]