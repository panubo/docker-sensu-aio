FROM debian:stretch

ENV DEBIAN_FRONTEND noninteractive

# Some dependencies
RUN apt-get update && \
  apt-get -y install curl sudo bc inotify-tools gnupg2 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install s6
RUN set -x \
  && S6_VERSION=2.7.1.1 \
  && S6_CHECKSUM=42ad7f2ae6028e7321e2acef432e7b9119bab5fb8748581ca729a2f92dacf613 \
  && EXECLINE_VERSION=2.5.0.0 \
  && EXECLINE_CHECKSUM=f65fba9eaea5d10d082ac75452595958af1f9ca8d298055539597de2f7b713cd \
  && SKAWARE_RELEASE=1.21.5 \
  && curl -sSf -L https://github.com/just-containers/skaware/releases/download/v${SKAWARE_RELEASE}/s6-${S6_VERSION}-linux-amd64-bin.tar.gz -o /tmp/s6-${S6_VERSION}-linux-amd64-bin.tar.gz \
  && curl -sSf -L https://github.com/just-containers/skaware/releases/download/v${SKAWARE_RELEASE}/execline-${EXECLINE_VERSION}-linux-amd64-bin.tar.gz -o /tmp/execline-${EXECLINE_VERSION}-linux-amd64-bin.tar.gz \
  && printf "%s  %s\n" "${S6_CHECKSUM}" "s6-${S6_VERSION}-linux-amd64-bin.tar.gz" "${EXECLINE_CHECKSUM}" "execline-${EXECLINE_VERSION}-linux-amd64-bin.tar.gz" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM; ) \
  && tar -C /usr -zxf /tmp/s6-${S6_VERSION}-linux-amd64-bin.tar.gz \
  && tar -C /usr -zxf /tmp/execline-${EXECLINE_VERSION}-linux-amd64-bin.tar.gz \
  && rm -rf /tmp/* \
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

ENV SENSU_VERSION 1.7.0
ENV SENSU_PKG_VERSION 2
ENV UCHIWA_VERSION 1.5.0
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
  && apt-get update \
  && apt-get install -y apt-transport-https \
  && groupadd -g 110 rabbitmq \
  && useradd -u 106 -g rabbitmq -c "RabbitMQ messaging server,,," -M -d "/var/lib/rabbitmq" -s /bin/false rabbitmq \
  && GPG_KEYS="0A9AF2115F4687BD29803A206B73A36E6026DFCA" \
  && ( gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEYS" \
      || gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$GPG_KEYS" \
      || gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$GPG_KEYS" ) \
  && gpg --armor --export "${GPG_KEYS}" | apt-key add - \
  && echo "deb https://dl.bintray.com/rabbitmq/debian stretch rabbitmq-server-v3.6.x" | tee /etc/apt/sources.list.d/rabbitmq.list \
  && echo "deb http://dl.bintray.com/rabbitmq-erlang/debian stretch erlang-20.x" | tee -a /etc/apt/sources.list.d/rabbitmq.list \
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
    sensu-cli \
    --no-rdoc --no-ri \
  && mkdir -p /etc/sensu/sensu-cli \
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

# Fix uchiwa config
RUN set -x \
  && mkdir /etc/uchiwa \
  && rm /etc/sensu/uchiwa.json /etc/uchiwa/uchiwa.json || true \
  ;

# Add config
COPY bin/ /
COPY rabbitmq.config.tmpl /etc/rabbitmq/rabbitmq.config.tmpl
COPY sensu-cli-settings.rb.tmpl /etc/sensu/sensu-cli/settings.rb.tmpl
COPY s6 /etc/s6/
COPY config.json.tmpl /etc/sensu/config.json.tmpl
COPY uchiwa.json.tmpl /etc/uchiwa/uchiwa.json.tmpl
COPY conf.d/ /etc/sensu/conf.d/

ENV BUILD_VERSION 1.7.0-1
