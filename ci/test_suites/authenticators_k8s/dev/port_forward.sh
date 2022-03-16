#!/bin/bash -e

source ./env.sh

if [ -f run/port_forward_inventory.pid ]; then
  exit "Port forwarder for inventory seems to be already running (check ./run dir)"
fi
if [ -f run/port_conjur.pid ]; then
  exit "Port forwarder for conjur seems to be already running (check ./run dir)"
fi

kubectl port-forward $inventory_pod_name 3080:80  2>&1 > log/port_forward_inventory.log &
echo $! > run/port_forward_inventory.pid

kubectl port-forward $authn_pod_name 3043:443 2>&1 > log/port_forward_conjur.log &
echo $! > run/port_forward_conjur.pid

echo Inventory is at http://localhost:3080
echo Conjur is at https://localhost:3043/ui
