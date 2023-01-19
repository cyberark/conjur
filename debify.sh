#!/bin/bash -ex

mkdir -p usr/local/bin
ln -sf /opt/conjur/possum/bin/conjur-possum usr/local/bin/

mkdir -p etc/conjur/nginx.d
cp opt/conjur/possum/distrib/nginx/* etc/conjur/nginx.d/

mkdir -p etc/service/conjur/possum/log
ln -sf /etc/service/conjur/plugin-service etc/service/conjur/possum/run
ln -sf /etc/service/conjur/plugin-logger  etc/service/conjur/possum/log/run

mkdir -p opt/conjur/etc
cp opt/conjur/possum/distrib/conjur/etc/* opt/conjur/etc/

mkdir -p opt/conjur/possum/config
