# Dockerizing Catmandu
#
# run this image with docker run -it ....
#

FROM debian:jessie
MAINTAINER Vitali Peil

RUN apt-get update && apt-get install -y \
  cpanminus \
  build-essential \
  libexpat1-dev \
  libssl-dev \
  libxml2-dev \
  libxslt1-dev \
  libgdbm-dev \
  libcapture-tiny-perl

COPY . /home/catmandu

WORKDIR /home/catmandu

RUN cpanm -n -q .
RUN perl Build.PL && ./Build
RUN ./Build test && ./Build install

WORKDIR /home

CMD ["/bin/bash"]
