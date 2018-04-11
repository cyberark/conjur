#!/bin/bash -e

cat << "CONFIGURE" | docker exec -i $(docker-compose ps -q conjur_4) bash
set -e

/opt/conjur/evoke/bin/wait_for_conjur
evoke ca regenerate conjur_4
/opt/conjur/evoke/bin/wait_for_conjur
env CONJUR_AUTHN_LOGIN=admin CONJUR_AUTHN_API_KEY=secret conjur policy load --as-group security_admin /etc/policy.yml
CONFIGURE

docker cp $(docker-compose ps -q conjur_4):/opt/conjur/etc/ssl/ca.pem ./tmp/conjur.pem
