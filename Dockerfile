FROM ubuntu:bionic AS updated
LABEL maintainer="torben.tietze@gmail.com"

# Update Ubuntu
RUN apt-get update && apt-get --yes dist-upgrade

#######

FROM updated AS builder

# Variables
ARG DAQ_URL=https://www.snort.org/downloads/snort/daq-2.0.7.tar.gz
ARG SNORT_URL=https://www.snort.org/downloads/snort/snort-2.9.16.tar.gz

# Install dependencies
RUN apt-get update && \
  apt-get install --yes --no-install-recommends \
  build-essential \
  # DAQ dependencies
  libpcap-dev \
  bison \
  flex \
  # Snort dependencies
  libpcre3-dev \
  libdumbnet-dev \
  zlib1g-dev \
  libnghttp2-dev \
  curl \
  ca-certificates \
  autotools-dev \
  automake

# Compile DAQ
RUN curl --location ${DAQ_URL} | tar xz
RUN cd daq-*  && ./configure && make && make install

# Compile Snort
RUN curl --location ${SNORT_URL} | tar xz
RUN cd snort-* && ./configure --enable-sourcefire --disable-open-appid && make && make install

#######

FROM updated

# Use baseimage-docker's init system.
#CMD ["/sbin/my_init"]

# Install dependencies
RUN apt-get update && apt-get install --yes --no-install-recommends \
  liblzma-dev \
  libssl-dev \
  libpcap-dev \
  libdumbnet-dev \
  libnghttp2-dev

COPY --from=builder /daq*/sfbpf/.libs/libsfbpf.so /usr/local/lib/
COPY --from=builder /usr/local/bin/snort /usr/local/bin/

RUN ldconfig

# Clean up APT when done.
RUN apt-get autoremove --yes && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN mkdir -p /etc/snort && touch /etc/snort/snort.conf /etc/snort/a.pcap

ENTRYPOINT ["snort","-l", "/var/log/snort/", "-c", "/etc/snort/snort.conf", "-r", "/etc/snort/a.pcap", "--process-all-events", "-N", "-x"]
