FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:brightbox/ruby-ng && \
    apt-get update -y

RUN apt-get install -y \
      build-essential \
      ruby2.5 ruby2.5-dev \
      postgresql-client \
      libpq-dev \
      unattended-upgrades \
      ldap-utils \
      git \
      curl \
      update-notifier-common \
      tzdata

RUN gem install -N -v 1.16.1 bundler

RUN mkdir -p /opt/conjur-server

WORKDIR /opt/conjur-server

ADD Gemfile      .
ADD Gemfile.lock .

RUN bundle --without test development

ADD . .

RUN ln -sf /opt/conjur-server/bin/conjurctl /usr/local/bin/

ENV PORT 80

EXPOSE 80

ENV RAILS_ENV production

ENTRYPOINT [ "conjurctl" ]
