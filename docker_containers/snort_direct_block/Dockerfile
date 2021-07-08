FROM ubuntu:xenial

ENV DAQ_VER=2.0.6 \
    SNORT_VER=2.9.11.1

# Install Dependencies
RUN apt-get update && \
    apt-get install -yqq build-essential autotools-dev bison flex gcc \
    	    	    	 libdumbnet-dev liblzma-dev libpcap-dev libpcre3-dev \
			 libssl-dev libluajit-5.1-dev pkg-config make  wget \
			 openssl zlib1g-dev libwlocate-dev cmake libtool \
			 autoconf libnetfilter-queue-dev libnghttp2-dev \
			 python 

# Optional packages
RUN apt-get install -yqq cpputest libsqlite3-dev uuid-dev 

RUN mkdir -p ~/snort_src && \
    cd ~/snort_src

# Install additional dependencies
# -safec
RUN cd ~/snort_src && \
    wget https://downloads.sourceforge.net/project/safeclib/libsafec-10052013.tar.gz && \
    tar -xzvf libsafec-10052013.tar.gz && \
    cd libsafec-10052013/ && \
    ./configure && make && make install 

# -Ragel
RUN cd  ~/snort_src && \
    wget http://www.colm.net/files/ragel/ragel-6.10.tar.gz && \
    tar -xzvf ragel-6.10.tar.gz && \
    cd ragel-6.10/ && \
    ./configure && make && make install 

# -Boost C++
RUN cd ~/snort_src && \
    wget https://dl.bintray.com/boostorg/release/1.65.1/source/boost_1_65_1.tar.gz && \
    tar -xvzf boost_1_65_1.tar.gz 

# -Hyperscan
RUN cd ~/snort_src && \
    wget https://github.com/intel/hyperscan/archive/v4.6.0.tar.gz && \
    tar -xvzf v4.6.0.tar.gz && \
    mkdir -p ~/snort_src/hyperscan-4.6.0-build && \
    cd ~/snort_src/hyperscan-4.6.0-build/ && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=~/snort_src/boost_1_65_1/ ../hyperscan-4.6.0 && \
    make && make install

# -flatbuffers
RUN cd ~/snort_src && \
    wget https://github.com/google/flatbuffers/archive/master.tar.gz -O flatbuffers-master.tar.gz && \
     tar -xvzf flatbuffers-master.tar.gz && \
     mkdir -p flatbuffers-build && \
     cd flatbuffers-build/ && \
     cmake ../flatbuffers-master && \
     make && make install 

# -DAQ
RUN cd ~/snort_src && \
    wget https://www.snort.org/downloads/archive/snort/daq-${DAQ_VER}.tar.gz && \
    tar -xvzf daq-${DAQ_VER}.tar.gz && \
    cd daq-${DAQ_VER} && \
    ./configure && make && make install 

# Update shared libraries cache
RUN ldconfig

# Install SNORT
RUN cd ~/snort_src && \
    wget https://www.snort.org/downloads/archive/snort/snort-${SNORT_VER}.tar.gz && \
    tar -xvzf snort-${SNORT_VER}.tar.gz && \
    cd snort-${SNORT_VER} && \
    ./configure --enable-sourcefire && make && make install 

RUN ln -s /opt/snort/bin/snort /usr/sbin/snort

RUN apt-get install -yqq ethtool

# Create Configuration & Log folders
RUN mkdir -p /etc/snort/ && mkdir -p /etc/snort/rules/ &&  \
    mkdir -p /var/log/snort/ && touch /etc/snort/snort.conf && \
    touch /etc/snort/rules/local.rules && touch /var/log/snort/alert

COPY snort.conf /etc/snort/snort.conf 
COPY local.rules /etc/snort/rules/local.rules 
COPY run.sh run.sh

CMD ["-Q", "--daq", "afpacket", "-i", "eth0:eth1", "-c", "/etc/snort/snort.conf", "-l", "/var/log/snort/"]

ENTRYPOINT ["/run.sh"]

