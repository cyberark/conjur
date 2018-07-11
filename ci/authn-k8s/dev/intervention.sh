#!/bin/bash -e

source ./conjurcmd.sh

echo "Performing intervention '$1'"
cat interventions/$1.yml | conjurcmd -i conjur policy load
