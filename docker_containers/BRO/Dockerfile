FROM ubuntu:xenial

ENV BRO_VER=2.6.3

# Install Dependencies
RUN apt-get update && \
    apt-get install -yqq build-essential autotools-dev automake autoconf gcc g++ \
    	    	    	 flex bison libssl-dev python-dev swig sendmail sendmail-bin \
    	    	    	 libpcap-dev zlib1g zlib1g-dev \
			 pkg-config make wget cmake libtool 

# Get source
RUN mkdir -p ~/bro_src && \
    cd ~/bro_src && \
    wget https://www.bro.org/downloads/bro-${BRO_VER}.tar.gz && \
    tar -xvzf bro-${BRO_VER}.tar.gz && \
    cd bro-${BRO_VER} && \
    ./configure --prefix=/usr && \
    make && make install 


# Create Configuration & Log folders
#RUN mkdir -p /etc/snort/ && mkdir -p /etc/snort/rules/ &&  \
#    mkdir -p /var/log/snort/ && touch /etc/snort/snort.conf && \
#    touch /etc/snort/rules/local.rules && touch /var/log/snort/alert

#COPY snort.conf /etc/snort/snort.conf 
#COPY local.rules /etc/snort/rules/local.rules 
COPY run.sh run.sh

CMD ["-i", "eth0"]

#CMD ["/bin/bash"]

ENTRYPOINT ["/run.sh"]

