FROM python:2.7

COPY requirements.txt /

RUN pip install -r /requirements.txt

WORKDIR /usr/local/bin

COPY includes/ ./includes

COPY sample.pcapng .

COPY demoKitScapy.py .

CMD ["demoKitScapy.py",  "-ieth0 -oeth1"]
