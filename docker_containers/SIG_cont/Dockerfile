FROM ubuntu:xenial

ARG GO_VER="1.13.9"
ENV sigID="sigE"
ENV sigIP="172.16.0.11"
ENV LOCAL_IP="127.0.0.1"
ENV GOPATH="/go"
ENV PATH="/.local/bin:$GOPATH/bin:/usr/local/go/bin:${PATH}"


RUN apt-get update && \
    apt-get install -yqq net-tools bridge-utils iproute2 git gcc

RUN apt-get install -yqq apt-transport-https ca-certificates openvpn && \
    echo "deb [trusted=yes] https://packages.netsec.inf.ethz.ch/debian all main" | tee /etc/apt/sources.list.d/scionlab.list && \
    apt-get update -qq && apt-get install -yqq scionlab 

RUN apt install -yqq scion-apps-webapp

RUN curl -O https://dl.google.com/go/go${GO_VER}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VER}.linux-amd64.tar.gz && \
    mkdir -p "$GOPATH"

RUN git clone -b scionlab https://github.com/netsec-ethz/scion && \
    cd /scion/go/sig && /usr/local/go/bin/go install && \
    /usr/local/go/bin/go build -o $GOPATH/bin/sig /scion/go/sig/main.go && \
    setcap cap_net_admin+eip $GOPATH/bin/sig && cd /

#RUN apt-get install kmod && modprobe dummy

#RUN apt-get install systemd

RUN scionlab-config --host-id=c890b056ccd8475eb099518d48ce9bc7 --host-secret=ae33af49c4fe46a393e909b944fed023

COPY sig.config sig.json topology.json run.sh /

ENTRYPOINT ["/run.sh"]



