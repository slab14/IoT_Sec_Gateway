FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -yqq net-tools bridge-utils iproute2 \
    iptables arptables tcpdump libcap-ng0 libcap-ng-dev \
    python python-pip autoconf libtool wget netcat curl \
    curl clang sparse flake8 graphviz automake python-dev \
    python3-pip build-essential pkg-config libssl-dev \
    gdb vim emacs jq uuid-runtime git bc bison flex \
    libncurses5-dev 

RUN pip3 install six pyftpdlib tftpy flake8

#RUN wget -O /usr/src/linux-source.tar.gz https://github.com/raspberrypi/linux/archive/04c8e47067d4873c584395e5cb260b4f170a99ea.tar.gz && \
#    tar -xzf /usr/src/linux-source.tar.gz -C /usr/src && \
#    touch /usr/src/linux-04c8e47067d4873c584395e5cb260b4f170a99ea/.scmversion && \
#    echo + | tee -a /usr/src/linux-04c8e47067d4873c584395e5cb260b4f170a99ea/.scmversion && \
#    ln -s /usr/src/linux-04c8e47067d4873c584395e5cb260b4f170a99ea /usr/src/linux && \
#    mkdir -p /lib/modules/$(uname -r)/build && \
#    mkdir -p /lib/modules/$(uname -r)/source && \        
#    ln -sf /usr/src/linux /lib/modules/$(uname -r)/build && \
#    ln -sf /usr/src/linux /lib/modules/$(uname -r)/source && \
#    cd /usr/src/linux && make modules && make modules_install && \
#    rm /usr/src/linux-source.tar.gz && cd ~

RUN git clone https://github.com/slab14/ovs.git && \
    cd ovs && git checkout feature-kernsign && \
    ./boot.sh && ./configure --prefix=/usr --localstatedir=/var \
    --sysconfdir=/etc && \
    #--with-linux=/lib/modules/$(uname -r)/build && \
    make && make install && \
    # rmmod openvswitch && \
    # rm /lib/modules/$(uname -r)/extra/openvswitch.ko && \
    # make modules_install && modprobe -v openvswitch && \
    cd ~ 


COPY run.sh run.sh

ENTRYPOINT ["/run.sh"]
