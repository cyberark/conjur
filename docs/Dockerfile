FROM jekyll/jekyll:4.0

ADD Gemfile Gemfile.lock /srv/jekyll/

ENV BUNDLER_VERSION 1.17.3
RUN gem install bundler -v $BUNDLER_VERSION

RUN bundle --without development
