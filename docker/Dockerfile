FROM possum-base

ADD tmp/conjur-possum.deb /tmp/

RUN dpkg -i /tmp/conjur-possum.deb

RUN mkdir -p /var/run/possum/policy

ENV PORT 80
ENV RACK_ENV production
ENV RUBY_DEP_GEM_SILENCE_WARNINGS 1

EXPOSE 80

ADD bin /usr/local/bin

WORKDIR /opt/conjur/possum
