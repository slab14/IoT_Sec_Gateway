FROM ubuntu:xenial

ENV SURICATA_VER=4.1.4

# Install Dependencies
RUN apt-get update && \
    apt-get install -yqq build-essential autotools-dev automake autoconf gcc \
    	    	    	 libpcap-dev libpcre3 libpcre3-dev libpcre3-dbg \
			 libnet1-dev libyaml-0-2 libyaml-dev zlib1g zlib1g-dev \
			 libjansson4 libcap-ng-dev libmagic-dev libjansson-dev \
			 libnfnetlink-dev pkg-config make wget libcap-ng0 \
			 cmake libtool libnetfilter-queue-dev  libnss3-dev\
			 libnetfilter-queue1 libnfnetlink0 python python-pip \
			 liblua5.1-dev libhiredis-dev libevent-dev python-yaml \
			 libnetfilter-log-dev libnetfilter-log1 rustc cargo

# Get source
RUN mkdir -p ~/suricata_src && \
    cd ~/suricata_src && \
    wget https://www.openinfosecfoundation.org/download/suricata-${SURICATA_VER}.tar.gz && \
    tar -xvzf suricata-${SURICATA_VER}.tar.gz && \
    cd suricata-${SURICATA_VER} && \
    ./configure --enable-nfqueue --prefix=/usr --sysconfdir=/ect --localstatedir=/var --enable-lua && \
    make && \
    #pip install --upgrade suricata-update && \
    make install-conf && \
    #make install-rules && \
    #make install-full && \
    ldconfig

# Create Configuration & Log folders
#RUN mkdir -p /etc/snort/ && mkdir -p /etc/snort/rules/ &&  \
#    mkdir -p /var/log/snort/ && touch /etc/snort/snort.conf && \
#    touch /etc/snort/rules/local.rules && touch /var/log/snort/alert

#COPY snort.conf /etc/snort/snort.conf 
#COPY local.rules /etc/snort/rules/local.rules 
COPY run.sh run.sh


CMD ["-c", "/root/suricata_src/suricata-4.1.4/suricata.yaml", "-i", "eth0"]


#CMD ["/bin/bash"]

ENTRYPOINT ["/run.sh"]

