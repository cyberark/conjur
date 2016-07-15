FROM ubuntu:14.04

RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:brightbox/ruby-ng && \
    apt-get update -y
    
RUN apt-get install -y \
      build-essential \
      ruby2.2 ruby2.2-dev \
      postgresql-client \
      libpq-dev \
      unattended-upgrades \
      ldap-utils \
      git \
      curl \
      update-notifier-common

RUN gem install -N -v 1.11.2 bundler

ADD Gemfile      .
ADD Gemfile.lock .

RUN mkdir -p /opt/possum

WORKDIR /opt/possum

RUN bundle

ADD . .

RUN ln -sf /opt/possum/bin/possum /usr/local/bin/

ENV PORT 80

EXPOSE 80

ENTRYPOINT [ "possum" ]
