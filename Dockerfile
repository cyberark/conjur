FROM ruby:2.2.5

RUN gem install -N bundler

RUN mkdir -p /opt/conjur
WORKDIR '/opt/conjur'

ADD Gemfile .
ADD Gemfile.lock .

RUN bundle
