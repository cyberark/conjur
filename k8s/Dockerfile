FROM ubuntu:latest
ARG namespace
MAINTAINER CyberArk

ENV INSTALL_DIR=/opt/conjur-openapi-spec

RUN mkdir -p $INSTALL_DIR
WORKDIR $INSTALL_DIR

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
CMD [ "sleep 9999" ]
