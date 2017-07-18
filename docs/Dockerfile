FROM ruby:2.2

RUN apt-get update && \
    apt-get install -y python-dev unzip && \
    curl -s "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

RUN apt-get install -y curl python-software-properties && \
    curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
    apt-get install -y nodejs

ADD Gemfile Gemfile.lock ./

RUN bundle --with website

ADD apidocs/package.json ./
RUN npm install

WORKDIR /opt/conjur
