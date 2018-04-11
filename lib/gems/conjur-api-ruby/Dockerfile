FROM ruby:2.3

RUN apt-get update && apt-get install -y vim curl

WORKDIR /src/conjur-api

COPY Gemfile conjur-api.gemspec ./
COPY lib/conjur-api/version.rb ./lib/conjur-api/

RUN bundle

COPY . ./

ENTRYPOINT ["/usr/local/bin/bundle", "exec"]
CMD ["rake", "jenkins"]
