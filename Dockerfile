FROM debian:jessie

MAINTAINER Tim Robinson <tim@panubo.com>

ENV DEBIAN_FRONTEND noninteractive

ENV SENSU_VERSION 0.21.0
ENV SENSU_PKG_VERSION 2

# Some dependencies
RUN apt-get update && \
  apt-get -y install curl sudo bc inotify-tools && \
  curl -L https://github.com/just-containers/skaware/releases/download/v1.16.1/s6-2.2.2.0-linux-amd64-bin.tar.gz | tar -C / -zxf -

CMD ["/usr/bin/s6-svscan","/etc/s6"]

# Setup sensu package repo & Install Sensu
RUN curl http://repositories.sensuapp.org/apt/pubkey.gpg | apt-key add - && \
  echo "deb     http://repositories.sensuapp.org/apt sensu main" | tee /etc/apt/sources.list.d/sensu.list && \
  apt-get update && \
  apt-get install sensu=${SENSU_VERSION}-${SENSU_PKG_VERSION} uchiwa && \
  echo "EMBEDDED_RUBY=true" > /etc/default/sensu

# Install RabbitMQ
RUN curl https://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add - && \
  echo "deb     http://www.rabbitmq.com/debian/ testing main" | tee /etc/apt/sources.list.d/rabbitmq.list && \
  apt-get install -y rabbitmq-server
VOLUME /var/lib/rabbitmq

# Install Redis
RUN apt-get install -y redis-server
VOLUME /var/lib/redis

# Install some gems
RUN /opt/sensu/embedded/bin/gem install \
  redphone \
  mail \
  pony \
  sensu-plugins-process-checks \
  sensu-plugins-ponymailer \
  --no-rdoc --no-ri

# Workaround handler-ponymailer.rb bug
# https://github.com/sensu-plugins/sensu-plugins-ponymailer/issues/3
#RUN ln -sf /opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/sensu-plugins-ponymailer-0.0.4/bin/handler-ponymailer.rb /opt/sensu/embedded/bin/handler-ponymailer.rb

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

# Add config
ADD s6 /etc/s6/
ADD config.json /etc/sensu/config.json
ADD client.json /etc/sensu/conf.d/client.json
ADD handler-default.json /etc/sensu/conf.d/handler-default.json
ADD check-sensu.json /etc/sensu/conf.d/check-sensu.json
ADD uchiwa.json /etc/sensu/uchiwa.json
ADD rabbitmq.config /etc/rabbitmq/rabbitmq.config
