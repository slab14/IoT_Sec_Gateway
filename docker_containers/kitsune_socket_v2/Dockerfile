FROM python:3-slim

RUN apt-get update && \
    apt-get install -yqq iproute2 ethtool


COPY requirements.txt /

RUN pip install -r /requirements.txt

COPY run.sh /

WORKDIR /usr/local/bin

COPY includes/ ./includes

COPY demoKitScapy.py .

CMD ["demoKitScapy.py",  "-i", "eth1",  "-o", "eth2"]

ENTRYPOINT ["/run.sh"]