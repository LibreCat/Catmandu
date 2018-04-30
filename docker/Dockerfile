# Minimal Dockerfile of a base image with Catmandu core on Debian stretch
FROM debian:stretch-slim

MAINTAINER LibreCat community <librecat-dev@lists.uni-bielefeld.de>

# Perl packages used by Catmandu (if available as Debian package) and cpanm
COPY apt.txt .
RUN apt-get update && apt-get install -y --no-install-recommends \
  $(grep -vE "^\s*#" apt.txt | tr "\n" " ") cpanminus \
  && rm -rf /var/lib/apt/lists/*

# Install current version of Catmandu from sources at CPAN
ENV CATMANDU_VERSION=1.09
RUN cpanm -n -q NICS/Catmandu-${CATMANDU_VERSION}.tar.gz

# Default command
CMD ["bash"]
