FROM possum

RUN gem install -N -v 0.8.1 yard
RUN gem install -N rake yard-cucumber redcarpet

WORKDIR /root

ADD . .

RUN mkdir -p .yard && yard config load_plugins true

ENV RUBYOPT "-E utf-8"

ENTRYPOINT [ "./yard-cucumber.sh" ]
