# Dockerizing Catmandu

FROM debian:jessie
MAINTAINER Vitali Peil

RUN apt-get update
RUN apt-get install -y cpanminus build-essential libexpat1-dev libssl-dev libxml2-dev libxslt1-dev libgdbm-dev libcapture-tiny-perl

RUN yes | cpanm Catmandu

CMD ["/bin/bash"]
