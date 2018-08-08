FROM centos:7

ENV DAQ_VER=2.0.6 \
    SNORT_VER=2.9.11.1

# Install Dependencies
RUN yum update && \
    yum install -y -q    build-essential autotools-dev bison flex gcc gcc-c++\
    	    	    	 libdnet-devel xz-devel libpcap-devel pcre-devel \
			 libssl-dev luajit-devel pkgconfig make \
			 openssl-devel zlib-devel cmake \
			 libnetfilter-queue-devel  hwloc-devel \
			 python ethtool epel-release libuuid-devel sqlite-devel

RUN yum remove -y cmake && \
    yum install -y -q wget && \
    wget https://cmake.org/files/v3.10/cmake-3.10.3.tar.gz && \
    tar xf cmake-3.10.3.tar.gz && \
    cd cmake-3.10.3 && \
    ./configure && make -j 8 && make install && \
    cd /

RUN mkdir -p ~/snort_src && \
    cd ~/snort_src

# Install additional dependencies
# -safec
RUN cd ~/snort_src && \
    wget https://downloads.sourceforge.net/project/safeclib/libsafec-10052013.tar.gz && \
    tar -xzvf libsafec-10052013.tar.gz && \
    cd libsafec-10052013/ && \
    ./configure --libdir=/usr/lib64 --includedir=/usr/include && make && make install 

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
    wget https://github.com/intel/hyperscan/archive/v4.7.0.tar.gz && \
    tar -xvzf v4.7.0.tar.gz && \
    mkdir -p ~/snort_src/hyperscan-4.7.0-build && \
    cd ~/snort_src/hyperscan-4.7.0-build/ && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=~/snort_src/boost_1_65_1/ ../hyperscan-4.7.0 && \
    make -j 8 && make install && \
    cp /usr/local/lib64/pkgconfig/libhs.pc /usr/lib64/pkgconfig/

# -flatbuffers
RUN cd ~/snort_src && \
    wget https://github.com/google/flatbuffers/archive/v1.8.0.tar.gz -O flatbuffers-v1.8.0.tar.gz && \
     tar -xvzf flatbuffers-v1.8.0.tar.gz && \
     mkdir -p flatbuffers-build && \
     cd flatbuffers-build/ && \
     cmake ../flatbuffers-1.8.0 && \
     make -j 8 && make install 

# -DAQ
RUN cd ~/snort_src && \
    wget https://www.snort.org/downloads/snort/daq-${DAQ_VER}.tar.gz && \
    tar -xvzf daq-${DAQ_VER}.tar.gz && \
    cd daq-${DAQ_VER} && \
    ./configure && make && make install 

# Update shared libraries cache
RUN ldconfig

# Install SNORT
RUN cd ~/snort_src && \
    wget https://www.snort.org/downloads/snort/snort-${SNORT_VER}.tar.gz && \
    tar -xvzf snort-${SNORT_VER}.tar.gz && \
    cd snort-${SNORT_VER} && \
    ./configure --enable-sourcefire && make && make install 

RUN ln -s /opt/snort/bin/snort /usr/sbin/snort

# Create Configuration & Log folders
RUN mkdir -p /etc/snort/ && mkdir -p /etc/snort/rules/ &&  \
    mkdir -p /var/log/snort/ && touch /etc/snort/snort.conf && \
    touch /etc/snort/rules/local.rules && touch /var/log/snort/alert

COPY snort.conf /etc/snort/snort.conf.default 
COPY local.rules /etc/snort/rules/local.rules.default 
COPY run.sh run.sh

CMD ["-Q", "--daq", "afpacket", "-i", "eth1:eth2", "-c", "/etc/snort/snort.conf", "-l", "/var/log/snort/"]

ENTRYPOINT ["/run.sh"]

