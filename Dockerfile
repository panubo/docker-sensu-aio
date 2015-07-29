FROM debian:jessie

MAINTAINER Tim Robinson <tim@panubo.com>

ENV DEBIAN_FRONTEND noninteractive

# Some dependencies
RUN apt-get update && \
  apt-get -y install curl sudo bc inotify-tools && \
  curl -L https://github.com/just-containers/skaware/releases/download/v1.14.0/s6-2.2.0.0-linux-amd64-bin.tar.gz | tar -C / -zxf -

CMD ["/usr/bin/s6-svscan","/etc/s6"]

# Setup sensu package repo
RUN curl http://repos.sensuapp.org/apt/pubkey.gpg | apt-key add - && \
  echo "deb     http://repos.sensuapp.org/apt sensu main" | tee /etc/apt/sources.list.d/sensu.list

# Install sensu
RUN apt-get update && \
  apt-get install sensu uchiwa && \
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
RUN ln -sf /opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/sensu-plugins-ponymailer-0.0.3/bin/handler-ponymailer.rb /opt/sensu/embedded/bin/handler-ponymailer.rb

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
ADD check-sensu.json /etc/sensu/conf.d/check-sensu.json
ADD uchiwa.json /etc/sensu/uchiwa.json
ADD rabbitmq.config /etc/rabbitmq/rabbitmq.config
