FROM registry2.itci.conjur.net/conjur-appliance-cuke-master:4.9-stable

RUN apt-get update && apt-get install -y zlib1g-dev

COPY conjur-authn-k8s.deb /tmp
RUN  dpkg -i /tmp/conjur-authn-k8s.deb && rm /tmp/conjur-authn-k8s.deb
