FROM registry2.itci.conjur.net/ubuntu-fips:18.04 as openSSL-builder
FROM ubuntu:20.04

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
                       tzdata \
                       # needed to build some gem native extensions:
                       libz-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/ssl/
COPY --from=openSSL-builder /usr/local/ssl/ /usr/local/ssl/
RUN ln -sf /usr/local/ssl/bin/openssl /usr/bin/openssl
# ENV OPENSSL_FIPS 1

RUN mkdir ~/.gnupg
RUN echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf

# install ruby compile with OpenSSL FIPS compliance
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    curl -sSL https://get.rvm.io | bash -s stable
RUN ["/bin/bash", "-c",  "source /usr/local/rvm/scripts/rvm; rvm install ruby-2.5.7 --with-openssl-dir=/usr/local/ssl"]
ENV PATH "/usr/local/rvm/rubies/ruby-2.5.7/bin:/usr/local/ssl/bin:${PATH}"
RUN ln -sf /usr/local/rvm/rubies/ruby-2.5.7/bin/ruby /usr/bin/ruby2.5

RUN gem install bundler:2.1.4

RUN rmdir /usr/local/ssl/certs && ln -sf /etc/ssl/certs/ /usr/local/ssl/

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
