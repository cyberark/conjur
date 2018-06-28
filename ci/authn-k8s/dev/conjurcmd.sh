#!/bin/bash -ex

function conjurcmd() {
  pod_name=$(kubectl get pods -l app=conjur-authn-k8s -o=jsonpath='{.items[].metadata.name}')
  interactive=$1
  if [ $interactive = '-i' ]; then
    shift
    kubectl exec -i $pod_name -- "$@"
  else
    kubectl exec $pod_name -- "$@"
  fi
}
