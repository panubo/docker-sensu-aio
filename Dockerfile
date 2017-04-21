FROM debian:jessie

MAINTAINER Tim Robinson <tim@panubo.com>

ENV DEBIAN_FRONTEND noninteractive

# Some dependencies
RUN apt-get update && \
  apt-get -y install curl sudo bc inotify-tools && \
  curl -L https://github.com/just-containers/skaware/releases/download/v1.19.1/s6-2.4.0.0-linux-amd64-bin.tar.gz | tar -C / -zxf - && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

CMD ["/bin/s6-svscan","/etc/s6"]

ENV SENSU_VERSION 0.26.5
ENV SENSU_PKG_VERSION 2
ENV UCHIWA_VERSION 0.22.0
ENV UCHIWA_PKG_VERSION 1

# Setup sensu package repo & Install Sensu
RUN curl http://repositories.sensuapp.org/apt/pubkey.gpg | apt-key add - && \
  echo "deb     http://repositories.sensuapp.org/apt sensu main" | tee /etc/apt/sources.list.d/sensu.list && \
  apt-get update && \
  apt-get install sensu=${SENSU_VERSION}-${SENSU_PKG_VERSION} uchiwa=${UCHIWA_VERSION}-${UCHIWA_PKG_VERSION} && \
  echo "EMBEDDED_RUBY=true" > /etc/default/sensu && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install RabbitMQ
RUN curl https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | apt-key add - && \
  echo "deb     http://www.rabbitmq.com/debian/ testing main" | tee /etc/apt/sources.list.d/rabbitmq.list && \
  apt-get update && \
  apt-get install -y rabbitmq-server && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*
VOLUME /var/lib/rabbitmq

# Install Redis
RUN apt-get update && \
  apt-get install -y redis-server && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*
VOLUME /var/lib/redis

# Install some gems
RUN /opt/sensu/embedded/bin/gem install \
  redphone \
  mail \
  pony \
  sensu-plugins-process-checks \
  sensu-plugins-ponymailer \
  sensu-plugins-pagerduty \
  --no-rdoc --no-ri

ENV PATH=/opt/sensu/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TMPDIR=/var/tmp
ENV LOGLEVEL=warn

# Expose some ports
# Rabbitmq
EXPOSE 5672
# Redis
#EXPOSE 6379
# Sensu API
EXPOSE 4567
# Uchiwa
EXPOSE 3000

RUN mkdir /etc/uchiwa && \
  mv /etc/sensu/uchiwa.json /etc/uchiwa/uchiwa.json

# Add config
ADD rabbitmq.config /etc/rabbitmq/rabbitmq.config
ADD s6 /etc/s6/
ADD config.json /etc/sensu/config.json
ADD conf.d/ /etc/sensu/conf.d/
ADD uchiwa.json /etc/uchiwa/uchiwa.json

ENV BUILD_VERSION 0.26.5-3
