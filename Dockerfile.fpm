# Build from the same version of ubuntu as phusion/baseimage
FROM @@image@@

RUN apt-get update -y && \
    apt-get purge -y ruby2.2 ruby2.2-dev && \
    apt-get install -y ruby2.5 ruby2.5-dev

ENV BUNDLER_VERSION 1.16.1
RUN gem install --no-rdoc --no-ri bundler:$BUNDLER_VERSION fpm

RUN mkdir -p /src/opt/conjur/project

WORKDIR /src/opt/conjur/project

COPY Gemfile ./
COPY Gemfile.lock ./

RUN bundle --deployment
RUN mkdir -p .bundle
RUN cp /usr/local/bundle/config .bundle/config

COPY . .
ADD debify.sh /

WORKDIR /src
