FROM registry.tld/cyberark/ubuntu-ruby-builder:22.04 as builder

WORKDIR ${CONJUR_HOME}

COPY Gemfile Gemfile.lock ./
COPY ./gems/ ./gems/

RUN bundle config set --local without 'test development' && \
    bundle config --local jobs "$(nproc --all)" && \
    bundle install

# removing CA bundle of httpclient gem
RUN find / -name httpclient -type d -exec find {} -name "*.pem" -type f -delete \;

FROM registry.tld/cyberark/ubuntu-ruby-fips:22.04
ENV PORT=80 \
    LOG_DIR=${CONJUR_HOME}/log \
    TMP_DIR=${CONJUR_HOME}/tmp \
    SSL_CERT_DIRECTORY=/opt/conjur/etc/ssl \
    RAILS_ENV=production

WORKDIR ${CONJUR_HOME}

# Ensure few required GID0-owned folders to run as a random UID (OpenShift requirement)
RUN mkdir -p $TMP_DIR \
             $LOG_DIR \
             $SSL_CERT_DIRECTORY/ca \
             $SSL_CERT_DIRECTORY/cert \
             /run/authn-local

COPY . .
COPY --from=builder ${CONJUR_HOME} ${CONJUR_HOME}
COPY --from=builder ${GEM_HOME} ${GEM_HOME}

EXPOSE ${PORT}

# testing only
RUN fips_mode -a disable
# testing only

ENTRYPOINT [ "conjurctl" ]

CMD [ "server" ]
