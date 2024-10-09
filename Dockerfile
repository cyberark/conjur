FROM cyberark/ubuntu-ruby-builder:latest AS builder

ENV CONJUR_HOME=/opt/conjur-server

WORKDIR ${CONJUR_HOME}

COPY Gemfile Gemfile.lock ./
COPY ./gems/ ./gems/

RUN bundle config set --local without 'test development' && \
    bundle config set --local deployment true && \
    bundle config set --local path vendor/bundle && \
    bundle config --local jobs "$(nproc --all)" && \
    bundle install && \
    # Remove private keys brought in by gems in their test data
    find / -name 'openid_connect-*' -type d -exec find {} -name '*.pem' -type f -delete \; && \
    find / -name 'httpclient-*' -type d -exec find {} -name '*.key' -type f -delete \; && \
    find / -name 'httpclient-*' -type d -exec find {} -name '*.pem' -type f -delete \;

FROM cyberark/ubuntu-ruby-fips:latest

ENV PORT=80 \
    LOG_DIR=${CONJUR_HOME}/log \
    TMP_DIR=${CONJUR_HOME}/tmp \
    SSL_CERT_DIRECTORY=/opt/conjur/etc/ssl \
    RAILS_ENV=production \
    CONJUR_HOME=/opt/conjur-server

ENV PATH="${PATH}:${CONJUR_HOME}/bin"

WORKDIR ${CONJUR_HOME}

# Ensure few required GID0-owned folders to run as a random UID (OpenShift requirement)
RUN mkdir -p $TMP_DIR \
             $LOG_DIR \
             $SSL_CERT_DIRECTORY/ca \
             $SSL_CERT_DIRECTORY/cert \
             /run/authn-local

COPY . .
COPY --from=builder ${CONJUR_HOME} ${CONJUR_HOME}

EXPOSE ${PORT}

ENTRYPOINT [ "conjurctl" ]
