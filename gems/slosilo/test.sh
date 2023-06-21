#!/bin/bash -xe

iid=slosilo-test-$(date +%s)

docker build -t $iid -f - . << EOF
  FROM ruby:3.0
  WORKDIR /app
  COPY Gemfile slosilo.gemspec ./
  RUN bundle
  COPY . ./
  RUN bundle
EOF

cidfile=$(mktemp -u)
docker run --cidfile $cidfile -v /app/spec/reports $iid bundle exec rake jenkins || :

cid=$(cat $cidfile)

docker cp $cid:/app/spec/reports spec/
docker cp $cid:/app/coverage spec

docker rm $cid

# untag, will use cache next time if available but no junk will be left
docker rmi $iid

rm $cidfile
