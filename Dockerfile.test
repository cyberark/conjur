ARG VERSION=latest
FROM conjur:${VERSION}

RUN bundle --no-deployment --without ''

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
