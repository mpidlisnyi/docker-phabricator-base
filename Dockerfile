FROM php:5.6-fpm
MAINTAINER maksim@nightbook.info

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
        ruby \
        python-pip \
        msmtp \
        git \
        openssh-client \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libldap2-dev \
        libpng12-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt pcntl mysql mysqli pdo pdo_mysql opcache \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) gd ldap \
    && pecl install APCu-4.0.10 \
    && docker-php-ext-enable apcu

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install pygments

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    REPOSITORY_LOCAL_PATH=/var/repo \
    PHABRICATOR_COMMIT=be84c05 \
    LIBPHUTIL_COMMIT=d6818e5 \
    ARCANIST_COMMIT=10e5194

RUN mkdir -p /srv $REPOSITORY_LOCAL_PATH
WORKDIR /srv
RUN git clone --branch stable https://github.com/phacility/libphutil.git libphutil && \
  cd libphutil && git checkout $LIBPHUTIL_COMMIT -b prod

RUN git clone --branch stable https://github.com/phacility/arcanist.git arcanist && \
  cd arcanist && git checkout $ARCANIST_COMMIT -b prod
RUN git clone --branch stable https://github.com/phacility/phabricator.git phabricator && \
  cd phabricator && git checkout $PHABRICATOR_COMMIT -b prod

COPY phabricator_configs_init.sh /phabricator_configs_init.sh
COPY msmtp.conf.erb /msmtp.conf.erb

RUN printf '#!/bin/sh\nexec msmtp -C /etc/msmtp.conf $*' > /usr/sbin/sendmail && chmod +x /usr/sbin/sendmail

WORKDIR /
