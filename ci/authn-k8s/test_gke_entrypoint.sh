#!/bin/bash -ex

set -o pipefail

# expects
# GCLOUD_CLUSTER_NAME GCLOUD_ZONE GCLOUD_PROJECT_NAME GCLOUD_SERVICE_KEY
# CONJUR_AUTHN_K8S_TEST_NAMESPACE CONJUR_AUTHN_K8S_TAG INVENTORY_TAG
# LOCAL_DEV_VOLUME
# to exist

export LOCAL_DEV_VOLUME=$(cat <<- ENDOFLINE
emptyDir: {}
ENDOFLINE
)

function finish {
  echo 'Finishing'
  echo '-----'

  {
    if [[ "$pod_name" != "" ]]; then
      echo "Grabbing output from $pod_name"
      echo '-----'
      mkdir -p output
      kubectl cp $pod_name:/opt/conjur-server/output output

      echo "Logs from Conjur Pod $pod_name:"
      kubectl logs $pod_name > output/gke-authn-k8s-logs.txt
    fi
  } || {
    echo "Logs could not be extracted from $pod_name"
    touch output/gke-authn-k8s-logs.txt  # so Jenkins artifact collection doesn't fail
  }

  echo 'Removing namespace $CONJUR_AUTHN_K8S_TEST_NAMESPACE'
  echo '-----'
  kubectl --ignore-not-found=true delete namespace $CONJUR_AUTHN_K8S_TEST_NAMESPACE

  delete_image $CONJUR_TEST_AUTHN_K8S_TAG
  delete_image $CONJUR_AUTHN_K8S_TAG
  delete_image $INVENTORY_TAG
  delete_image $NGINX_TAG
}
trap finish EXIT

export TEMPLATE_TAG=gke.
export API_VERSION=rbac.authorization.k8s.io/v1beta1

function main() {
  sourceFunctions
  renderResourceTemplates
  
  initialize
  createNamespace

  pushDockerImages

  launchConjurMaster
  
  copyNginxSSLCert
  
  copyConjurPolicies
  loadConjurPolicies
  
  launchInventoryServices

  runTests
}

function sourceFunctions() {
  source dev/utils.sh
  source dev/templatecmd.sh
  source dev/conjurcmd.sh
}

function renderResourceTemplates() {
  cleanuptemplatescmd $TEMPLATE_TAG
  compiletemplatescmd <(echo '') $TEMPLATE_TAG
}

function initialize() {
  # setup kubectl
  gcloud auth activate-service-account --key-file $GCLOUD_SERVICE_KEY
  gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_NAME
}

function createNamespace() {
  # clean ups namespaces older than minutes or seconds
  old_namespaces=$(kubectl get namespaces | awk '$1 ~ /test-/ && $3 !~ /[m|s]/ { print $1; }')
  [ ! -z ${old_namespaces} ] && kubectl delete --ignore-not-found=true namespaces ${old_namespaces}

  kubectl create namespace $CONJUR_AUTHN_K8S_TEST_NAMESPACE
  kubectl config set-context $(kubectl config current-context) --namespace=$CONJUR_AUTHN_K8S_TEST_NAMESPACE

  # Grant default service account permissions it needs for authn-k8s to:
  # 1) get + list various resources
  # 2) create + get pods/exec (to inject cert into app sidecar)
  kubectl apply -f dev/dev_conjur_authenticator_role.${TEMPLATE_TAG}yaml
  wait_for_it 1 "kubectl get clusterrole conjur-authenticator"
  kubectl create -f dev/dev_conjur_authenticator_role_binding.${TEMPLATE_TAG}yaml
}

function pushDockerImages() {
  gcloud docker -- push $CONJUR_AUTHN_K8S_TAG
  gcloud docker -- push $CONJUR_TEST_AUTHN_K8S_TAG
  gcloud docker -- push $INVENTORY_TAG
  gcloud docker -- push $NGINX_TAG
}

function launchConjurMaster() {
  echo 'Launching Conjur master service'

  sed -e "s#{{ CONJUR_AUTHN_K8S_TAG }}#$CONJUR_AUTHN_K8S_TAG#g" dev/dev_conjur.${TEMPLATE_TAG}yaml |
    sed -e "s#{{ CONJUR_TEST_AUTHN_K8S_TAG }}#$CONJUR_TEST_AUTHN_K8S_TAG#g" |
    sed -e "s#{{ DATA_KEY }}#$(openssl rand -base64 32)#g" |
    sed -e "s#{{ CONJUR_AUTHN_K8S_TEST_NAMESPACE }}#$CONJUR_AUTHN_K8S_TEST_NAMESPACE#g" |
    kubectl create -f -

  conjur_pod=$(kubectl get pods -l app=conjur-authn-k8s -o=jsonpath='{.items[].metadata.name}')

  wait_for_it 300 "kubectl describe po $conjur_pod | grep Status: | grep -q Running"

  # wait for the 'conjurctl server' entrypoint to finish
  kubectl exec $conjur_pod -- bash -c "while ! curl -sI localhost:80 > /dev/null; do sleep 1; done"
  
  export API_KEY=$(kubectl exec $conjur_pod -- conjurctl account create cucumber | tail -n 1 | awk '{ print $NF }')
}

function copyNginxSSLCert() {
  nginx_pod=$(kubectl get pods -l app=nginx-authn-k8s -o=jsonpath='{.items[].metadata.name}')
  cucumber_pod=$(kubectl get pods -l app=cucumber-authn-k8s -o=jsonpath='{.items[].metadata.name}')

  kubectl cp $nginx_pod:/etc/nginx/nginx.crt ./nginx.crt
  kubectl cp ./nginx.crt $cucumber_pod:/opt/conjur-server/nginx.crt
}

function copyConjurPolicies() {
  cli_pod=$(kubectl get pod -l app=conjur-cli --no-headers | grep Running | awk '{ print $1 }')

  kubectl cp ./dev/policies $cli_pod:/policies
}

function loadConjurPolicies() {
  echo 'Loading the policies and data'

  cli_pod=$(kubectl get pod -l app=conjur-cli --no-headers | grep Running | awk '{ print $1 }')
  
  kubectl exec $cli_pod -- conjur init -u conjur -a cucumber
  sleep 5
  kubectl exec $cli_pod -- conjur authn login -u admin -p $API_KEY

  # load policies
  kubectl exec $cli_pod -- conjur policy load root /policies/policy.${TEMPLATE_TAG}yml

  # init ca certs
  conjur_pod=$(kubectl get pod -l app=conjur-authn-k8s --no-headers | grep Running | awk '{ print $1 }')
  kubectl exec $conjur_pod -- rake authn_k8s:ca_init["conjur/authn-k8s/minikube"]
}

function launchInventoryServices() {
  echo 'Launching inventory services'

  kubectl create -f dev/dev_inventory.${TEMPLATE_TAG}yaml
  kubectl create -f dev/dev_inventory_stateful.${TEMPLATE_TAG}yaml
  kubectl create -f dev/dev_inventory_pod.${TEMPLATE_TAG}yaml
  kubectl create -f dev/dev_inventory_unauthorized.${TEMPLATE_TAG}yaml

  wait_for_it 300 "kubectl describe po inventory | grep Status: | grep -c Running | grep -q 4"
}

function runTests() {
  echo 'Running tests'

  conjurcmd mkdir -p /opt/conjur-server/output

  echo "./bin/cucumber K8S_VERSION=1.7 PLATFORM=kubernetes --no-color --format pretty --format junit --out /opt/conjur-server/output -r ./cucumber/kubernetes/features/step_definitions/ -r ./cucumber/kubernetes/features/support/world.rb -r ./cucumber/kubernetes/features/support/hooks.rb -r ./cucumber/kubernetes/features/support/conjur_token.rb --tags ~@skip ./cucumber/kubernetes/features" | cucumbercmd -i bash
}

main
