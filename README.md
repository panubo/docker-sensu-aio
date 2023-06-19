# DEPRECATED - this is an obsolete version of Sensu that should no longer be used

## Sensu All in One

This image is a quick way to get started with Sensu. It includes the following

* Sensu-server
* Sensu-api
* Sensu-client (can be disabled)
* Redis
* RabbitMQ
* Uchiwa (A sensu web UI)

### Example

```
# Start the sensu server
docker run -d -v `pwd`/conf.d/:/etc/sensu/conf.d/ --name sensu -p 3000:3000 panubo/sensu-aio

# Start an monitoring container
docker run -d --hostname $HOSTNAME -v /:/host/:ro --link sensu:sensu panubo/monitor

# Open browser to http://127.0.0.1:3000/
```

### Options

The following Environment variables can be defined

```
LOGLEVEL=warn # Sets the log level for the sensu apps. info|warn|error
```

### Connecting

Ports for RabbitMQ, sensu-api and uchiwa are exposed.

### Config

Most of sensu config belongs in `/etc/sensu/conf.d`. The main sensu config file is `/etc/sensu/config.json` and is templated by the container bootstrap. It will always be overwritten however the main sensu config has the lowest priority so can easily be overridden by the config in `/etc/sensu/conf.d` .

One method to manage this is to mount /etc/sensu/conf.d to the host and edit from there. This image includes a watcher on that directory to restart the sensu-server when changes are detected on any `*.json` files in that directory.

The following config can also be configured via environment variables.

* `SENSU_API_USER` Sensu API username
* `SENSU_API_PASS` Sensu API password
* `SENSU_UCHIWA_USER` Uchiwa UI username
* `SENSU_UCHIWA_PASS` Uchiwa UI password

**Note: if /etc/uchiwa/uchiwa.json already exists the template will not be applied**

## SSL

```
# Testing and development instructions only. Don't run these commands in prod.
# Generate SSL certs following the README.md in the ssl/ directory

# Start sensu-aio with SSL support
docker run -d -v $(pwd)/conf.d/:/etc/sensu/conf.d/ -v $(pwd)/ssl:/etc/sensu/ssl -a SENSU_SSL=true --name sensu -p 3000:3000 panubo/sensu-aio
```

### SSL Options

* `SENSU_SSL` required, enable SSL support. (Leave unset to disable)
* `SENSU_CACERT` optional, path to CA Certificate. `/etc/sensu/ssl/root_ca.pem`
* `SENSU_SERVER_CERT` optional, path to rabbitmq server certificate. `/etc/sensu/ssl/server.pem`
* `SENSU_SERVER_KEY` options, path to rabbitmq server private key. `/etc/sensu/ssl/server-key.pem`
* `SENSU_CLIENT_CERT` optional, path to sensu server certificate. `/etc/sensu/ssl/sensu.pem`
* `SENSU_CLIENT_KEY` options, path to sensu server private key. `/etc/sensu/sssl/sensu-key.pem`

## Rabbitmq security

By default rabbitmq and sensu are configured to use the default guest rabbitmq user and the default `/` vhost. The following variable will configure sensu to use an alternate set of rabbitmq credentials and vhost.

* `SENSU_RABBITMQ_SECURITY` restricts the guest user to loopback, leave unset to disable.
* `SENSU_RABBITMQ_SERVER_USER`
* `SENSU_RABBITMQ_SERVER_PASS`
* `SENSU_RABBITMQ_VHOST`

Rabbitmq is not automatically configured to use these variables however a script has been provided to configure them. Once the container has started and rabbitmq is running (should only be a few seconds later) run `docker exec sensu /rabbitmq-init-server` to configure rabbitmq.

There is also a script provided to add sensu client users to rabbitmq. The command `docker exec sensu /rabbitmq-add-user` will use the variables listed below to configure a sensu client user or you can pass a username and password to the script instead. For example `docker exec sensu /rabbitmq-add-user USERNAME PASSWORD`

* `SENSU_RABBITMQ_CLIENT_USER`
* `SENSU_RABBITMQ_CLIENT_PASS`

### Local client

This images comes configured with sensu-client but really provides no value and should probably not be used. As such if /etc/sensu/conf.d/client.json is missing the local client will not be started. Use another client like [panubo/monitor](https://github.com/panubo/docker-monitor) to actually start using sensu properly.

### Versions

The image tag is related to the sensu version package in the image. The version major, minor and patch will match the sensu version exactly however the revision will not necessarily match the sensu package revision. The revision is incremented with the docker image instead of the debian package revision.

