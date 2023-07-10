#!/bin/bash -e

source ./conjurcmd.sh

echo Rotating database password

new_password=$(openssl rand -hex 12)

echo $new_password | conjurcmd -i conjur variable values add inventory-db/password

