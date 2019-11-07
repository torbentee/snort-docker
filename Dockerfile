FROM phusion/baseimage:master-amd64

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Update Ubuntu
RUN apt-get update && apt-get --yes dist-upgrade

# Install dependencies
RUN apt-get install -y \
  build-essential \
  libpcap-dev \
  libpcre3-dev \
  libdumbnet-dev \
  bison \
  flex \
  zlib1g-dev \
  liblzma-dev \
  openssl \
  libssl-dev \
  libnghttp2-dev

# Compile DAQ
RUN curl --location --output daq.tar.gz https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
RUN tar xzf daq.tar.gz
RUN cd daq-2.0.6/  && ./configure && make && make install

# Compile Snort
RUN curl --location --output snort.tar.gz https://www.snort.org/downloads/snort/snort-2.9.15.tar.gz
RUN tar xzf snort.tar.gz
RUN cd snort-2.9.15/ && ./configure --enable-sourcefire --disable-open-appid && make && make install

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /snort* /daq*

RUN ldconfig
