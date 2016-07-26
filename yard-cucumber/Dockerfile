FROM possum

RUN gem install -N rake yard-cucumber

RUN mkdir -p /opt/yard-cucumber

WORKDIR /opt/yard-cucumber

ADD . .

RUN yard config load_plugins true

ENV RUBYOPT "-E utf-8"

ENTRYPOINT [ "./yard-cucumber.sh" ]
