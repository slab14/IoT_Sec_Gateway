FROM python:3-slim

COPY requirements.txt run.sh /

RUN apt-get update && \
    apt-get install -yqq iproute2 ethtool && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install -r /requirements.txt

COPY includes/ /usr/local/bin/includes

COPY demoKitScapy.py /usr/local/bin

CMD ["demoKitScapy.py",  "-i", "eth1",  "-o", "eth2"]

ENTRYPOINT ["/run.sh"]