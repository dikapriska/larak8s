FROM ubuntu:18.04

MAINTAINER Dika Priska <dikapriska@gmail.com>

RUN apt-get clean && apt-get -y update && apt-get install -y locales && locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US.UTF-8' LC_ALL='en_US.UTF-8'

RUN apt-get clean && apt-get update -y \
    && DEBIAN_FRONTEND="noninteractive" TZ="Asia/Jakarta" apt-get install -y nginx curl iputils-ping zip unzip git software-properties-common nano net-tools supervisor libxrender1 libxext6 mysql-client libssh2-1-dev tzdata \
    && add-apt-repository ppa:ondrej/php -y \
    && apt-get clean \
    && apt-get update \
    && apt-get install -y wget git php7.4-fpm php7.4-cli php7.4-gd php7.4-mysql \
       php7.4-imap php7.4-memcached php7.4-mbstring php7.4-xml php7.4-curl \
       php7.4-zip php7.4-pdo-dblib php7.4-bcmath \
    && php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
    && mkdir /run/php

RUN update-ca-certificates;

RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -

RUN apt-get clean && apt-get update -y && apt-get install apt-transport-https -y

RUN echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

RUN apt-get clean && apt-get update && apt-get install filebeat -y

COPY filebeat.yml /etc/filebeat/filebeat.yml

RUN apt-get remove -y --purge software-properties-common \
	&& apt-get -y autoremove \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
	&& echo "daemon off;" >> /etc/nginx/nginx.conf

RUN ln -sf /dev/stdout /var/log/nginx/docker.access.log \
    && ln -sf /dev/stderr /var/log/nginx/docker.error.log

COPY default /etc/nginx/sites-available/default

COPY php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf

COPY www.conf /etc/php/7.4/fpm/pool.d/www.conf

COPY php.ini /etc/php/7.4/fpm/php.ini

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /app

RUN git clone -b 7.x https://github.com/laravel/laravel /app

RUN cp .env.example .env

RUN composer install

RUN php artisan key:generate

RUN chown -R www-data:www-data /app

EXPOSE 80

CMD ["/usr/bin/supervisord"]
