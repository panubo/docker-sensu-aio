#!/usr/bin/env bash

rabbitmqctl add_vhost $SENSU_RABBITMQ_VHOST
rabbitmqctl add_user $SENSU_RABBITMQ_SERVER_USER $SENSU_RABBITMQ_SERVER_PASS
rabbitmqctl add_user $SENSU_RABBITMQ_CLIENT_USER $SENSU_RABBITMQ_CLIENT_PASS
rabbitmqctl set_permissions -p $SENSU_RABBITMQ_VHOST $SENSU_RABBITMQ_SERVER_USER '.*' '.*' '.*'

rabbitmqctl set_permissions -p $SENSU_RABBITMQ_VHOST $SENSU_RABBITMQ_CLIENT_USER '((?!keepalives|results).)*' '.*' '((?!keepalives|results).)*'
