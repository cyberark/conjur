# kics-scan disable=fd54f200-402c-4333-a5a4-36ef6709af2f
FROM jekyll/jekyll:4.0

ADD Gemfile Gemfile.lock /srv/jekyll/

ENV BUNDLER_VERSION 2.4.14
RUN gem install bundler -v $BUNDLER_VERSION

RUN bundle --without development
