FROM ruby:2.2.5

RUN gem install -N bundler

RUN mkdir -p /opt/possum
WORKDIR '/opt/possum'

ADD Gemfile .
ADD Gemfile.lock .

RUN bundle
