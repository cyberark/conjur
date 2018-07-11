FROM ruby:2.3

RUN gem install -N activesupport --version 4.2.7.1
RUN gem install -N conjur-api:"< 5.0" conjur-cli:"< 6.0" sinatra

COPY inventory.rb usr/src/inventory.rb

# allow anyone to write to this dir, container may not run as root
RUN mkdir -p /etc/conjur/ssl && chmod 777 /etc/conjur/ssl

env PORT 80

CMD [ "ruby", "/usr/src/inventory.rb" ]
