# Alpine Linux, Apache2, PHP7 Docker Stack

![Build](https://github.com/duy0611/alpine-php-apache-stack/workflows/Build/badge.svg)

Link to DockerHub: [Docker Hub](https://hub.docker.com/r/duy0611/alpine-php-apache)

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

## Running container

The container can be run as following: `docker run --rm -d -p 80:80 --name webserver alpine-php-apache:latest`

Or via docker-compose:
```
version: '3.5'

services:
  webserver:
    image: alpine-php-apache
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - 80:80
    volumes:
      - ./logs/apache2/:/usr/local/apache2/logs/
      - ./logs/php7/:/usr/local/php7/var/log/
      - ./www_data/:/usr/local/apache2/htdocs/
```

To test the webserver, execute following: `docker exec -it webserver php -i`

