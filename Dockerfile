FROM php:7.1.11-apache

LABEL maintainer="Majid Abdolhosseini <majid@mhndev.com>"


ENV CASSANDRA_PHP_DRIVER_VERSION 1.3.2

RUN rm /var/lib/apt/lists/* -vrf && \
    apt-get clean && apt-get update

RUN apt-get update && \
    apt-get install -y git wget libssl-dev zlib1g-dev libicu-dev g++ make cmake libuv-dev libgmp-dev uuid-dev && \
    apt-get autoclean -y && \
    apt-get clean -y

# Install datastax php-driver fox cassandra
RUN git clone https://github.com/datastax/php-driver.git /usr/src/datastax-php-driver && \
    cd /usr/src/datastax-php-driver && \
    git checkout --detach v${CASSANDRA_PHP_DRIVER_VERSION} && \
    git submodule update --init && \
    cd ext && \
    ./install.sh && \
    echo extension=cassandra.so > /usr/local/etc/php/conf.d/cassandra.ini

# Install PHP extensions
RUN docker-php-ext-install zip mbstring intl opcache bcmath && \
    echo extension=bcmath.so > /usr/local/etc/php/conf.d/docker-php-ext-bcmath.ini && \
    pecl install xdebug && \
    echo zend_extension=xdebug.so > /usr/local/etc/php/conf.d/xdebug.ini && \
    pecl install apcu-5.1.5 && \
    echo extension=apcu.so > /usr/local/etc/php/conf.d/apcu.ini && \
    pecl install uuid && \
    echo extension=uuid.so > /usr/local/etc/php/conf.d/uuid.ini


RUN a2enmod rewrite
RUN echo "\nServerName localhost\n" >> /etc/apache2/apache2.conf


RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

## Cleanup
RUN apt-get purge -y \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
