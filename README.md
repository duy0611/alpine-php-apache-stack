# Alpine Linux, Apache2, PHP7 Docker Stack

The repository contains Dockerfile for alpine-apache-php stack.

Some information about the dockerfile:
- Start with alpine base image
- Apache 2.4.x and PHP 7.3.x are compiled and installed from latest source
- Include extra php modules: phpredis and xdebug (modules are also compiled and installed from latest source)

## Files structure

```
.
├── Dockerfile          # Dockerfile to build alpine-apache-php image
├── Makefile
├── README.md
├── docker-compose.yml  # Entrypoint for docker-compose target
├── php_config          # PHP config file
│   └── php.ini
└── www_data            # Example php files for testing webserver
    ├── index.php
    └── info.php
```

## How to

To build docker image: `make build-docker`

To run docker container: `make run-docker`

To stop docker container: `make stop-docker`

To run docker compose with binding volumes (logs and www_data): `make run-docker-compose`

To stop docker compose: `make stop-docker-compose`
