## SSL

```
# Generate the root CA
cfssl gencert -initca csr_root_ca.json | cfssljson -bare root_ca

# Generate the rabbitmq server certificate
cfssl gencert -ca root_ca.pem -ca-key root_ca-key.pem -config config.json -profile server csr_server.json | cfssljson -bare server

# Generate the sensu-server certificate (uses the client profile)
cfssl gencert -ca root_ca.pem -ca-key root_ca-key.pem -config config.json -profile client csr_client.json | cfssljson -bare sensu
cat root_ca.pem >> sensu.pem

# Generate the sensu client certificates
CLIENT_CN=client1
cfssl gencert -ca root_ca.pem -ca-key root_ca-key.pem -config config.json -profile client -cn ${CLIENT_CN} csr_client.json | cfssljson -bare ${CLIENT_CN}
cat root_ca.pem >> ${CLIENT_CN}.pem
```

## RabbitMQ SSL Authentication

https://github.com/rabbitmq/rabbitmq-auth-mechanism-ssl/blob/v3.7.3/README.md
