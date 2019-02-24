FROM phusion/baseimage:0.9.22

RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:brightbox/ruby-ng && \
    apt-get update -y

RUN apt-get update -y && \
    apt-get install -y \
    build-essential \
    ruby2.5 ruby2.5-dev \
    postgresql-client \
    libpq-dev \
    unattended-upgrades \
    ldap-utils \
    git \
    update-notifier-common \
    vim \
    curl \
    jq \
    tzdata

RUN echo Installing phantomjs && \
    apt-get update -y && \
    apt-get install -y build-essential \
                       chrpath \
                       libfreetype6 \
                       libfreetype6-dev \
                       libfontconfig1 \
                       libfontconfig1-dev \
                       libssl-dev \
                       libxft-dev \
                       wget

ENV PHANTOM_JS="phantomjs-1.9.8-linux-x86_64"

RUN cd ~ && \
    wget https://bitbucket.org/ariya/phantomjs/downloads/${PHANTOM_JS}.tar.bz2 && \
    tar xvjf $PHANTOM_JS.tar.bz2 && \
    mv $PHANTOM_JS /usr/local/share && \
    ln -sf /usr/local/share/${PHANTOM_JS}/bin/phantomjs /usr/local/bin && \
    phantomjs --version

RUN gem install -N -v 1.16.2 bundler

RUN mkdir -p /src/conjur-server

ADD .irbrc /root
ADD .pryrc /root

WORKDIR /src/conjur-server

ADD Gemfile      .
ADD Gemfile.lock .

RUN bundle

RUN rm /etc/service/sshd/down
RUN ln -sf /src/conjur-server/bin/conjurctl /usr/local/bin/

ENV PORT 3000
ENV TERM xterm

EXPOSE 3000
