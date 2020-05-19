ARG ALPINE_VERSION=3.11
ARG APACHE_PREFIX=/usr/local/apache2
ARG APACHE_VERSION=2.4.43
ARG PHP_PREFIX=/usr/local/php7
ARG PHP_VERSION=7.3.18


#####################################################
# Compile and Install Apache 2.4.x from latest source
FROM alpine:${ALPINE_VERSION} AS apache2-base

# See https://httpd.apache.org/docs/2.4/install.html#requirements
RUN apk add --no-cache \
        # runtime deps
        apr-dev \
		apr-util-dbm_db \
		apr-util-dev \
		apr-util-ldap \
		perl \
        # core
        ca-certificates \
		coreutils \
		dpkg-dev dpkg \
		gcc \
		gnupg \
		libc-dev \
		# mod_md
		curl-dev \
		jansson-dev \
		# mod_proxy_html mod_xml2enc
		libxml2-dev \
		# mod_lua
		lua-dev \
		make \
		# mod_http2
		nghttp2-dev \
		# mod_session_crypto
		openssl \
		openssl-dev \
		pcre-dev \
		tar \
		# mod_deflate
		zlib-dev \
		# mod_brotli
		brotli-dev

# Ensure www-data user exists
RUN set -x \
	&& addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data

ARG APACHE_PREFIX
ARG APACHE_VERSION
ENV PATH ${APACHE_PREFIX}/bin:$PATH
RUN mkdir -p "$APACHE_PREFIX" chown www-data:www-data "$APACHE_PREFIX"

WORKDIR $APACHE_PREFIX

# Download Apache source binaries
RUN wget https://archive.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz && \
    gzip -d httpd-${APACHE_VERSION}.tar.gz && \
    tar xvf httpd-${APACHE_VERSION}.tar && \
    rm httpd-${APACHE_VERSION}.tar

# Compile and Install Apache source binaries
RUN cd httpd-${APACHE_VERSION} && \
    ./configure --prefix=${APACHE_PREFIX} --enable-so && \
    make && \
    make install && \
    cd ../ && rm -rf httpd-${APACHE_VERSION} && \
    # smoke test
    httpd -v && \
    rm -rf /var/cache/apk/*


##################################################
# Compile and Install PHP 7.3.x from latest source
FROM alpine:${ALPINE_VERSION} AS php7-apache2-base		

# persistent / runtime deps
RUN apk add --no-cache \
		ca-certificates \
		curl \
		tar \
		xz \
		openssl

# php deps
RUN apk add --no-cache \
		autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c \
		argon2-dev \
		coreutils \
		curl-dev \
		libedit-dev \
		libsodium-dev \
		libxml2-dev \
		openssl-dev \
		sqlite-dev

# Ensure www-data user exists
RUN set -x \
	&& addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data

ARG APACHE_PREFIX
ARG PHP_PREFIX
ARG PHP_VERSION
ENV PATH ${PHP_PREFIX}/bin:$PATH
RUN mkdir -p "$PHP_PREFIX" chown www-data:www-data "$PHP_PREFIX"

WORKDIR $PHP_PREFIX

RUN wget https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz && \
    gzip -d php-${PHP_VERSION}.tar.gz && \
    tar xvf php-${PHP_VERSION}.tar && \
    rm php-${PHP_VERSION}.tar

# Copy apache2 binaries from base
RUN apk add --no-cache apr-dev apr-util-dev perl
COPY --from=apache2-base ${APACHE_PREFIX} ${APACHE_PREFIX}

RUN cd php-${PHP_VERSION} && \
    ./configure --prefix=${PHP_PREFIX} --with-apxs2=${APACHE_PREFIX}/bin/apxs && \
    make && make install && \
    cd ../ && rm -rf php-${PHP_VERSION} && \
    # smoke test
    php -i && \
    rm -rf /var/cache/apk/*


#########################################
# Compile and Install extra PHP modules #
FROM php7-apache2-base AS php7-apache2-base-extra

# Compile and Install phpredis module
RUN wget https://pecl.php.net/get/redis-5.2.2.tar && \
    tar xvf redis-5.2.2.tar && \
    cd redis-5.2.2 && phpize && ./configure --enable-redis && make && make install && \
    cd ../ && rm redis-5.2.2.tar && rm -rf redis-5.2.2/

# Compile and Install xdebug module
RUN wget https://pecl.php.net/get/xdebug-2.9.5.tar && \
    tar xvf xdebug-2.9.5.tar && \
    cd xdebug-2.9.5 && phpize && ./configure --enable-xdebug && make && make install && \
    cd ../ && rm xdebug-2.9.5.tar && rm -rf xdebug-2.9.5/


#############################
##### Main docker image #####
FROM alpine:${ALPINE_VERSION}

# Persistent / runtime deps
RUN apk --no-cache add ca-certificates curl tar xz openssl bash

# Ensure www-data user exists
RUN set -x \
	&& addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data

ARG APACHE_PREFIX
ARG APACHE_VERSION
ENV PATH ${APACHE_PREFIX}/bin:$PATH
RUN mkdir -p "$APACHE_PREFIX" chown www-data:www-data "$APACHE_PREFIX"

ARG PHP_PREFIX
ARG PHP_VERSION
ENV PATH ${PHP_PREFIX}/bin:$PATH
RUN mkdir -p "$PHP_PREFIX" chown www-data:www-data "$PHP_PREFIX"

# Copy apache2 binaries from base
RUN apk add --no-cache apr apr-util pcre zlib
COPY --from=php7-apache2-base-extra ${APACHE_PREFIX} ${APACHE_PREFIX}

# Copy php7 binaries from base
RUN apk add --no-cache argon2-libs libedit libxml2
COPY --from=php7-apache2-base-extra ${PHP_PREFIX} ${PHP_PREFIX}

# Update httpd.conf with PHP modules
RUN printf "\nDirectoryIndex index.php index.html\n\n<FilesMatch \\.php$>\n\tSetHandler application/x-httpd-php\n</FilesMatch>\n" >> ${APACHE_PREFIX}/conf/httpd.conf

# Add php.ini
COPY php_config/php.ini ${PHP_PREFIX}/lib/php.ini

# HTTP PORT
EXPOSE 80

# Start Apache2 server
CMD ["httpd", "-D", "FOREGROUND"]
