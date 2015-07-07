## Sensu All in One

This image is a quick way to get started with Sensu. It includes the following

* Sensu-server
* Sensu-api
* Sensu-client (can be disabled)
* Redis
* RabbitMQ
* Uchiwa

### Example

```
# Start the sensu server
docker run -d -v `pwd`/conf.d/:/etc/sensu/conf.d/ --name sensu -p 3000:3000 trnubo/sensu-aio

# Start an monitoring container
docker run -d --hostname $HOSTNAME -v /:/host/:ro --link sensu:sensu trnubo/monitor

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

Most of sensu config belongs in /etc/sensu/conf.d

One method to manage this is to mount /etc/sensu/conf.d to the host and edit from there. This image includes a watcher on that directory to restart the sensu-server when changes are detected on any .json files.

### Local client

This images comes configured with sensu-client but really provides no value and should probably not be used. As such if /etc/sensu/conf.d/client.json is missing the local client will not be started. Use another client like trnubo/monitor to actually start using sensu properly.
