FROM cyberark/ubuntu-ruby-fips:latest

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
COPY gems/ gems/


RUN bundle --without test development

COPY . .

# removing CA bundle of httpclient gem
RUN find / -name httpclient -type d -exec find {} -name *.pem -type f -delete \;

RUN ln -sf /opt/conjur-server/bin/conjurctl /usr/local/bin/

ENV RAILS_ENV production

ENTRYPOINT [ "conjurctl" ]
