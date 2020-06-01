FROM ubuntu:xenial

ENV DAQ_VER=2.0.7 \
    SNORT_VER=2.9.16

# Install Dependencies
RUN apt-get update && \
    apt-get install -yqq build-essential autotools-dev bison flex gcc \
    	    	    	 libdumbnet-dev liblzma-dev libpcap-dev libpcre3-dev \
			 libssl-dev libluajit-5.1-dev pkg-config make  wget \
			 openssl zlib1g-dev libwlocate-dev cmake libtool \
			 autoconf libnetfilter-queue-dev libnghttp2-dev \
			 python python-pip libsqlite3-dev uuid-dev ethtool && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p ~/snort_src && \
    cd ~/snort_src && \
# Install additional dependencies
# -safec
    cd ~/snort_src && \
    wget https://downloads.sourceforge.net/project/safeclib/libsafec-10052013.tar.gz && \
    tar -xzvf libsafec-10052013.tar.gz && \
    rm libsafec-10052013.tar.gz && \
    cd libsafec-10052013/ && \
    ./configure && make && make install && \
    rm -rf ~/snort_src/libsafec-10052013 && \
# -Ragel
    cd  ~/snort_src && \
    wget http://www.colm.net/files/ragel/ragel-6.10.tar.gz && \
    tar -xzvf ragel-6.10.tar.gz && \
    rm ragel-6.10.tar.gz && \
    cd ragel-6.10/ && \
    ./configure && make && make install && \
    rm -rf ~/snort_src/ragel-6.10

# -DAQ
RUN cd ~/snort_src && \
    wget https://www.snort.org/downloads/snort/daq-${DAQ_VER}.tar.gz && \
    tar -xvzf daq-${DAQ_VER}.tar.gz && \
    rm daq-${DAQ_VER}.tar.gz && \
    cd daq-${DAQ_VER} && \
    ./configure && make && make install && \
    ldconfig && \
    rm -rf ~/snort_src/daq-${DAQ_VER} && \
# Install SNORT
    cd ~/snort_src && \
    wget https://www.snort.org/downloads/snort/snort-${SNORT_VER}.tar.gz && \
    tar -xvzf snort-${SNORT_VER}.tar.gz && \
    rm snort-${SNORT_VER}.tar.gz && \
    cd snort-${SNORT_VER} && \
    ./configure --enable-sourcefire && make && make install && \
    ln -s /opt/snort/bin/snort /usr/sbin/snort && \
    rm -rf ~/snort_src/snort-${SNORT_VER} && \
    rm -rf ~/snort_src/ && \
# Create Configuration & Log folders
    mkdir -p /etc/snort/ && mkdir -p /etc/snort/rules/ &&  \
    mkdir -p /var/log/snort/ && touch /etc/snort/snort.conf && \
    touch /etc/snort/rules/local.rules && touch /var/log/snort/alert

# tools for sending alerts
RUN pip install watchdog 

COPY snort.conf /etc/snort/snort.conf.default 
COPY local.rules /etc/snort/rules/local.rules.default 
COPY run.sh getAlerts.py sendAlerts.c ./

CMD ["-Q", "--daq", "afpacket", "--daq-var", "buffer_size_mb=1", "-i", "eth1:eth2", "-c", "/etc/snort/snort.conf", "-l", "/var/log/snort/"]

ENTRYPOINT ["/run.sh"]