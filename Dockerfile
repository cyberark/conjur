FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive \
    PORT=80 \
    LOG_DIR=/opt/conjur-server/log \
    TMP_DIR=/opt/conjur-server/tmp \
    SSL_CERT_DIRECTORY=/opt/conjur/etc/ssl

EXPOSE 80

RUN apt-get update -y && \
    apt-get -y dist-upgrade && \
    apt-get install -y build-essential \
                       curl \
                       git \
                       libpq-dev \
                       ldap-utils \
                       postgresql-client \
                       ruby2.5 ruby2.5-dev \
                       tzdata \
                       # needed to build some gem native extensions:
                       libz-dev \
    && rm -rf /var/lib/apt/lists/*

RUN gem install rake
RUN gem install -N -v 1.17.3 bundler
RUN gem install http -v4.2.0

WORKDIR /opt/conjur-server

# Ensure few required GID0-owned folders to run as a random UID (OpenShift requirement)
RUN mkdir -p $TMP_DIR \
             $LOG_DIR \
             $SSL_CERT_DIRECTORY/ca \
             $SSL_CERT_DIRECTORY/cert \
             /run/authn-local

COPY Gemfile \
     Gemfile.lock ./

RUN bundle --without test development

COPY . .

RUN ln -sf /opt/conjur-server/bin/conjurctl /usr/local/bin/

ENV RAILS_ENV production

# The Rails initialization expects the database configuration
# and data key to exist. We supply placeholder values so that
# the asset compilation can complete.
RUN DATABASE_URL=postgresql:does_not_exist \
    CONJUR_DATA_KEY=$(openssl rand -base64 32) \
    bundle exec rake assets:precompile

ENTRYPOINT [ "conjurctl" ]
