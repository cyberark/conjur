#!/bin/bash -e

cat << "CONFIGURE" | docker exec -i $(docker-compose ps -q conjur_5) bash
set -e

for _ in $(seq 20); do
  curl -o /dev/null -fs -X OPTIONS http://localhost > /dev/null && break
  echo .
  sleep 2
done

# So we fail if the server isn't up yet:
curl -o /dev/null -fs -X OPTIONS http://localhost > /dev/null
CONFIGURE
