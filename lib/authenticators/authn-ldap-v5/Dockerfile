FROM ruby:2.5.0

RUN apt-get update -y && \
    apt-get install -y \
      build-essential \
      ldap-utils \
      curl \
      tzdata

RUN gem install --no-document -v 1.16 bundler

RUN mkdir -p /opt/authn-ldap
WORKDIR /opt/authn-ldap

ADD Gemfile      .
ADD Gemfile.lock .
RUN bundle

ADD . .

EXPOSE 80
ENV RACK_ENV production

CMD ["bundle", "exec", "rackup", "-p", "80", "-o", "0.0.0.0"]
