# Minimal Dockerfile of a base image with Catmandu core on Debian stretch
FROM debian:stretch-slim

MAINTAINER LibreCat community <librecat-dev@lists.uni-bielefeld.de>

ADD docker/apt.txt .
# Perl packages used by Catmandu (if available as Debian package) and cpanm
RUN apt-get update && apt-get install -y --no-install-recommends \
  $(grep -vE "^\s*#" apt.txt | tr "\n" " ") cpanminus \
  && rm -rf /var/lib/apt/lists/*

ADD . /tmp/catmandu

WORKDIR /tmp/catmandu

# install from source
RUN cpanm -n -q --installdeps --skip-satisfied .
RUN perl Build.PL && ./Build && ./Build install

# cleanup sources 
WORKDIR /
RUN rm -rf /tmp/catmandu

# make user feel home
RUN adduser --home /home/catmandu --uid 1000 --disabled-password --gecos "" catmandu
WORKDIR /home/catmandu
USER catmandu

# Default command
CMD ["bash"]
