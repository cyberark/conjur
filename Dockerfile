FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive \
    PORT=80 \
    LOG_DIR=/opt/conjur-server/log \
    TMP_DIR=/opt/conjur-server/tmp \
    SSL_CERT_DIRECTORY=/opt/conjur/etc/ssl

EXPOSE 80

RUN apt-get update -y && \
    apt-get -y dist-upgrade && \
    apt-get -y install software-properties-common && \
    apt-add-repository ppa:brightbox/ruby-ng

RUN apt-get update -y && \
    apt-get install -y build-essential \
                       curl \
                       git \
                       libpq-dev \
                       ldap-utils \
                       postgresql-client \
                       ruby2.5 ruby2.5-dev \
                       tzdata \
                       # needed to build some gem native extensions: \
                       libz-dev \
    && rm -rf /var/lib/apt/lists/*

RUN gem install --no-document --version 2.1.4 bundler

WORKDIR /opt/conjur-server

# Ensure few required GID0-owned folders to run as a random UID (OpenShift requirement)
RUN mkdir -p $TMP_DIR \
             $LOG_DIR \
             $SSL_CERT_DIRECTORY/ca \
             $SSL_CERT_DIRECTORY/cert \
             /run/authn-local

COPY Gemfile \
     Gemfile.lock ./
COPY gems/ gems/


RUN bundle --without test development

COPY . .

RUN ln -sf /opt/conjur-server/bin/conjurctl /usr/local/bin/

ENV RAILS_ENV production

ENTRYPOINT [ "conjurctl" ]
