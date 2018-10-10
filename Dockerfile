FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

ENV PORT 80

EXPOSE 80

RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:brightbox/ruby-ng

RUN apt-get update -y && \
    apt-get install -y build-essential \
                       curl \
                       git \
                       libpq-dev \
                       ldap-utils \
                       postgresql-client \
                       ruby2.5 ruby2.5-dev \
                       tzdata \
                       unattended-upgrades \
                       update-notifier-common

RUN gem install -N -v 1.16.1 bundler

RUN mkdir -p /opt/conjur-server

WORKDIR /opt/conjur-server

COPY Gemfile \
     Gemfile.lock ./

RUN bundle --without test development

COPY . .

RUN ln -sf /opt/conjur-server/bin/conjurctl /usr/local/bin/

ENV RAILS_ENV production

ENTRYPOINT [ "conjurctl" ]
