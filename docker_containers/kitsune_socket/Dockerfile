FROM python:3-slim

COPY requirements.txt /

RUN pip install -r /requirements.txt

COPY run.sh /

WORKDIR /usr/local/bin

COPY includes/ ./includes

COPY demoKitScapy.py .

CMD ["demoKitScapy.py",  "-i", "eth0",  "-o", "eth1"]

ENTRYPOINT ["/run.sh"]