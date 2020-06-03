FROM registry.tld/ruby-fips-base-image-ubuntu:1.0.0

ENV DEBIAN_FRONTEND=noninteractive \
    PORT=80 \
    LOG_DIR=/opt/conjur-server/log \
    TMP_DIR=/opt/conjur-server/tmp \
    SSL_CERT_DIRECTORY=/opt/conjur/etc/ssl

EXPOSE 80

RUN apt-get update -y && \
    apt-get -y dist-upgrade && \
    apt-get install -y libz-dev
RUN apt-get install -y build-essential \
                       curl \
                       git \
                       ldap-utils \
                       tzdata \
    && rm -rf /var/lib/apt/lists/*

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

ENTRYPOINT [ "conjurctl" ]
