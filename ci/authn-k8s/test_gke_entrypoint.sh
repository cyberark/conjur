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
  gcloud container images delete --force-delete-tags -q \
    $CONJUR_AUTHN_K8S_TAG $INVENTORY_TAG
}
#trap finish EXIT

export TEMPLATE_TAG=gke.
export API_VERSION=rbac.authorization.k8s.io/v1beta1

function main() {
  sourceFunctions
  renderResourceTemplates
  
  initializeKubeCtl
  createNamespace

  pushDockerImages

  launchConjurMaster
#  createSSLCertConfigMap
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

function initializeKubeCtl() {
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
  gcloud docker -- push $INVENTORY_TAG
}

function launchConjurMaster() {
  echo 'Launching Conjur master service'

  sed -e "s#{{ CONJUR_AUTHN_K8S_TAG }}#$CONJUR_AUTHN_K8S_TAG#g" dev/dev_conjur.${TEMPLATE_TAG}yaml |
    sed -e "s#{{ DATA_KEY }}#$(openssl rand -base64 32)#g" |
    sed -e "s#{{ CONJUR_AUTHN_K8S_TEST_NAMESPACE }}#$CONJUR_AUTHN_K8S_TEST_NAMESPACE#g" |
    kubectl create -f -

#  echo 'Disabling unused services'
#  for service in authn-tv ldap ldap-sync pubkeys rotation; do
#    conjurcmd touch /etc/service/conjur/$service/down
#  done

#  echo 'Enabling authn-k8s'

#  conjurcmd sv stop conjur nginx pg && sleep 3
#  conjurcmd evoke ca regenerate conjur-authn-k8s
#  conjurcmd rm -f /etc/service/conjur/authn-k8s/down

#  conjurcmd mkdir -p /src/authn-k8s

#  WORKSPACE_PARENT_DIR=$(dirname $PWD)
#  tar --exclude="./*.deb" --exclude="./*.git" -zcvf $WORKSPACE_PARENT_DIR/src.tgz .
#  kubectl cp $WORKSPACE_PARENT_DIR/src.tgz $pod_name:/src/
#  rm -rf $WORKSPACE_PARENT_DIR/src.tgz
#  conjurcmd tar -zxvf /src/src.tgz -C /src/authn-k8s

#  conjurcmd /opt/conjur/evoke/bin/dev-install authn-k8s

  # authn-k8s must be in "development" mode to allow request IP spoofing, which is used by the 
  # test cases.
  pod_name=$(kubectl get pods -l app=conjur-authn-k8s -o=jsonpath='{.items[].metadata.name}')

  wait_for_it 300 "kubectl describe po $pod_name | grep Status: | grep -q Running"

  kubectl exec $pod_name -- conjurctl db migrate
  export API_KEY=$(kubectl exec $pod_name -- conjurctl account create cucumber | tail -n 1 | awk '{ print $NF }')
  
#  kubectl cp $pod_name:/opt/conjur/etc/authn-k8s.conf ./dev/tmp/authn-k8s.conf
#  cat << CONFIG >> ./dev/tmp/authn-k8s.conf
#  RAILS_ENV=development
#  RAILS_LOG_TO_STDOUT=true
#CONFIG

#  kubectl cp ./dev/tmp/authn-k8s.conf $pod_name:/opt/conjur/etc/authn-k8s.conf

#  conjurcmd sv start nginx pg conjur
#  conjurcmd /opt/conjur/evoke/bin/wait_for_conjur
}

function createSSLCertConfigMap() {
  echo 'Storing non-secret configuration data'

  ssl_certificate=$(conjurcmd cat /opt/conjur/etc/ssl/conjur.pem)

  # write out conjur ssl cert in configmap
  kubectl delete --ignore-not-found=true configmap conjurrc
  kubectl create configmap conjurrc \
    --from-literal=ssl-certificate="$ssl_certificate"
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
  kubectl exec $cli_pod -- conjur policy load root /policies/users.${TEMPLATE_TAG}yml
  kubectl exec $cli_pod -- conjur policy load root /policies/apps.${TEMPLATE_TAG}yml
  kubectl exec $cli_pod -- conjur policy load root /policies/authn-k8s.${TEMPLATE_TAG}yml
  kubectl exec $cli_pod -- conjur policy load root /policies/entitlements.${TEMPLATE_TAG}yml

  # init ca certs
  conjur_pod=$(kubectl get pod -l app=conjur-authn-k8s --no-headers | grep Running | awk '{ print $1 }')
  kubectl exec $conjur_pod -- rake authn_k8s:ca_init["conjur/authn-k8s/minikube"]

  # set test password value
  password=$(openssl rand -hex 12)
  kubectl exec $cli_pod -- conjur variable values add inventory-db/password $password
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

  echo "./bin/cucumber K8S_VERSION=1.7 PLATFORM=kubernetes --no-color --format pretty --format junit --out /opt/conjur-server/output -r ./cucumber/kubernetes/features/step_definitions/ -r ./cucumber/kubernetes/features/env.rb -r ./cucumber/kubernetes/features/support/world.rb ./cucumber/kubernetes/features" | conjurcmd -i bash
}

main
