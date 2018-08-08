FROM centos:7

RUN yum update && \
    yum install -y -q squid httpd-tools ethtool iproute

RUN touch /etc/squid/passwords 

COPY squid.conf /etc/squid/squid.conf

EXPOSE 13128/tcp

COPY run.sh /
COPY update_password.sh /
COPY remove_password.sh /
COPY add_password.sh /

CMD ["squid", "-NYCd", "1"]

ENTRYPOINT ["/run.sh"] 