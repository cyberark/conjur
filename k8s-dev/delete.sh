#!/bin/bash -x

kubectl delete secret conjur-data-key

kubectl delete -f dev_pg.yaml
kubectl delete -f dev_conjur.yaml
kubectl delete -f dev_cli.yaml
