FROM debian:stretch

ENV DEBIAN_FRONTEND noninteractive

# Some dependencies
RUN apt-get update && \
  apt-get -y install curl sudo bc inotify-tools gnupg2 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install s6
RUN set -x \
  && S6_VERSION=2.6.1.1 \
  && EXECLINE_VERSION=2.3.0.3 \
  && SKAWARE_RELEASE=1.21.2 \
  && curl -sS -L https://github.com/just-containers/skaware/releases/download/v${SKAWARE_RELEASE}/s6-${S6_VERSION}-linux-amd64-bin.tar.gz | tar -C /usr -zxf - \
  && curl -sS -L https://github.com/just-containers/skaware/releases/download/v${SKAWARE_RELEASE}/execline-${EXECLINE_VERSION}-linux-amd64-bin.tar.gz | tar -C /usr -zxf - \
  ;
CMD ["/usr/bin/s6-svscan","/etc/s6"]

# Install gomplate
RUN set -x \
  && GOMPLATE_VERSION=v2.5.0 \
  && GOMPLATE_CHECKSUM=f4cc9567c1a7b3762af175cf9d941fddef3b5032354c210604fb015c229104c7 \
  && curl -sS -o /tmp/gomplate_linux-amd64-slim -L https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64-slim \
  && echo "${GOMPLATE_CHECKSUM}  gomplate_linux-amd64-slim" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM; ) \
  && mv /tmp/gomplate_linux-amd64-slim /usr/local/bin/gomplate \
  && chmod +x /usr/local/bin/gomplate \
  && rm -f /tmp/* \
  ;

ENV SENSU_VERSION 1.4.2
ENV SENSU_PKG_VERSION 1
ENV UCHIWA_VERSION 1.2.0
ENV UCHIWA_PKG_VERSION 1

# Setup sensu package repo & Install Sensu, uid:gid sensu 999:999 uchiwa 998:998
RUN set -x \
  && curl http://repositories.sensuapp.org/apt/pubkey.gpg | apt-key add - \
  && echo "deb     http://repositories.sensuapp.org/apt stretch main" | tee /etc/apt/sources.list.d/sensu.list \
  && apt-get update \
  && apt-get install sensu=${SENSU_VERSION}-${SENSU_PKG_VERSION} uchiwa=${UCHIWA_VERSION}-${UCHIWA_PKG_VERSION} \
  && echo "EMBEDDED_RUBY=true" > /etc/default/sensu \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install RabbitMQ, uid:gid 106:110
RUN set -x \
  && groupadd -g 110 rabbitmq \
  && useradd -u 106 -g rabbitmq -c "RabbitMQ messaging server,,," -M -d "/var/lib/rabbitmq" -s /bin/false rabbitmq \
  && curl https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | apt-key add - \
  && echo "deb     http://www.rabbitmq.com/debian/ testing main" | tee /etc/apt/sources.list.d/rabbitmq.list \
  && apt-get update \
  && apt-get install -y rabbitmq-server \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;
VOLUME /var/lib/rabbitmq

# Install Redis, uid:gid 107:111
RUN set -x \
  && groupadd -g 111 redis \
  && useradd -u 107 -g redis -M -d "/var/lib/redis" -s /bin/false redis \
  && apt-get update \
  && apt-get install -y redis-server \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;
VOLUME /var/lib/redis

# Install some gems
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y build-essential \
  && /opt/sensu/embedded/bin/gem install \
    sensu-plugins-process-checks \
    sensu-plugins-mailer \
    sensu-plugins-pagerduty \
    --no-rdoc --no-ri \
  && apt-get remove -y build-essential \
  && apt-get -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

ENV PATH=/opt/sensu/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TMPDIR=/var/tmp
ENV LOGLEVEL=warn
ENV SENSU_CACERT=/etc/sensu/ssl/root_ca.pem SENSU_SERVER_CERT=/etc/sensu/ssl/server.pem SENSU_SERVER_KEY=/etc/sensu/ssl/server-key.pem SENSU_CLIENT_CERT=/etc/sensu/ssl/sensu.pem SENSU_CLIENT_KEY=/etc/sensu/ssl/sensu-key.pem
ENV SENSU_RABBITMQ_SERVER_USER=guest SENSU_RABBITMQ_SERVER_PASS=guest SENSU_RABBITMQ_VHOST=/ 

# Expose some ports
# Rabbitmq ssl 5671/tcp non-ssl 5672/tcp
EXPOSE 5671 5672
# Redis
#EXPOSE 6379
# Sensu API
EXPOSE 4567
# Uchiwa
EXPOSE 3000

RUN mkdir /etc/uchiwa && \
  mv /etc/sensu/uchiwa.json /etc/uchiwa/uchiwa.json

# Add config
COPY rabbitmq.config.tmpl /etc/rabbitmq/rabbitmq.config.tmpl
COPY s6 /etc/s6/
COPY config.json.tmpl /etc/sensu/config.json.tmpl
COPY conf.d/ /etc/sensu/conf.d/
COPY uchiwa.json /etc/uchiwa/uchiwa.json
COPY reload /reload
COPY security.sh /security.sh

ENV BUILD_VERSION 1.4.2-1
