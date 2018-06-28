# Run this script as:
# source ./env.sh

# Exports minikube docker into the environment
# Sets environment variables conjur_pod_name and account_factory_pod_name

eval $(minikube docker-env)
authn_pod_name=$(kubectl get pods -l app=conjur-authn-k8s -o=jsonpath='{.items[].metadata.name}')
inventory_pod_name=$(kubectl get pods -l app=inventory-deployment -o=jsonpath='{.items[].metadata.name}')
stateful_inventory_pod_name=$(kubectl get pods -l app=inventory-stateful -o=jsonpath='{.items[].metadata.name}')
