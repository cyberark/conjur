#!/bin/bash -ex

set -o pipefail

# expects
# PLATFORM K8S_VERSION OPENSHIFT_USERNAME OPENSHIFT_PASSWORD
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
      kubectl cp $pod_name:/src/authn-k8s/output output

      echo "Logs from Conjur Pod $pod_name:"
      oc logs $pod_name > "output/$PLATFORM-authn-k8s-logs.txt"
    fi
  } || {
    echo "Logs could not be extracted from $pod_name"
    touch "output/$PLATFORM-authn-k8s-logs.txt"  # so Jenkins artifact collection doesn't fail
  }

  echo 'Removing namespace $CONJUR_AUTHN_K8S_TEST_NAMESPACE'
  echo '-----'

  oc adm policy remove-scc-from-user anyuid -z default
  oc --ignore-not-found=true delete project $CONJUR_AUTHN_K8S_TEST_NAMESPACE
}
trap finish EXIT

export TEMPLATE_TAG="$PLATFORM."
export API_VERSION=v1

function main() {
  sourceFunctions
  renderResourceTemplates
  
  initializeKubeCtl
  createNamespace

  pushDockerImages

  launchConjurMaster
  createSSLCertConfigMap
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
  # setup kubectl, oc and docker
  oc login $OPENSHIFT_URL --username=$OPENSHIFT_USERNAME --password=$OPENSHIFT_PASSWORD --insecure-skip-tls-verify=true
  docker login -u _ -p $(oc whoami -t) $OPENSHIFT_REGISTRY_URL
}

function createNamespace() {
  # clean ups namespaces older than minutes or seconds
  old_namespaces=$(kubectl get namespaces | awk '$1 ~ /test-/ && $3 !~ /[m|s]/ { print $1; }')
  [ ! -z ${old_namespaces} ] && kubectl delete --ignore-not-found=true namespaces ${old_namespaces}

  oc new-project $CONJUR_AUTHN_K8S_TEST_NAMESPACE
  oc project $CONJUR_AUTHN_K8S_TEST_NAMESPACE

#  kubectl config set-context $(kubectl config current-context) --namespace=$CONJUR_AUTHN_K8S_TEST_NAMESPACE

  oc adm policy add-scc-to-user anyuid -z default
  oc delete --ignore-not-found=true clusterrole conjur-authenticator

  # Grant default service account permissions it needs for authn-k8s to:
  # 1) get + list various resources
  # 2) create + get pods/exec (to inject cert into app sidecar)
  oc create -f dev/dev_conjur_authenticator_role.${TEMPLATE_TAG}yaml
  wait_for_it 1 "oc get clusterrole conjur-authenticator"
  oc create -f dev/dev_conjur_authenticator_role_binding.${TEMPLATE_TAG}yaml

  # docker pull secrets
  oc secrets new-dockercfg dockerpullsecret \
   --docker-server=${OPENSHIFT_REGISTRY_URL} --docker-username=_ \
   --docker-password=$(oc whoami -t) --docker-email=_
  oc secrets add serviceaccount/default secrets/dockerpullsecret --for=pull
}

function pushDockerImages() {
  # push images to openshift registry
  docker push $CONJUR_AUTHN_K8S_TAG
  docker push $INVENTORY_TAG
}

function launchConjurMaster() {
  echo 'Launching Conjur master service'

  oc create -f dev/dev_conjur.${TEMPLATE_TAG}yaml
  wait_for_it 300 "oc describe po conjur-authn-k8s | grep Status: | grep -q Running"

  echo 'Disabling unused services'
  for service in authn-tv ldap ldap-sync pubkeys rotation; do
    conjurcmd touch /etc/service/conjur/$service/down
  done

  echo 'Enabling authn-k8s'

  conjurcmd sv stop conjur nginx pg && sleep 3
  conjurcmd evoke ca regenerate conjur-authn-k8s
  conjurcmd rm -f /etc/service/conjur/authn-k8s/down

  conjurcmd mkdir -p /src/authn-k8s

  WORKSPACE_PARENT_DIR=$(dirname $PWD)
  tar --exclude="./*.deb" --exclude="./*.git" -zcvf $WORKSPACE_PARENT_DIR/src.tgz .
  kubectl cp $WORKSPACE_PARENT_DIR/src.tgz $pod_name:/src/
  rm -rf $WORKSPACE_PARENT_DIR/src.tgz
  conjurcmd tar -zxvf /src/src.tgz -C /src/authn-k8s

  conjurcmd /opt/conjur/evoke/bin/dev-install authn-k8s

  # authn-k8s must be in "development" mode to allow request IP spoofing, which is used by the 
  # test cases.
  pod_name=$(oc get pods -l app=conjur-authn-k8s -o=jsonpath='{.items[].metadata.name}')

  echo "Conjur pod name is : $pod_name"

  kubectl cp $pod_name:/opt/conjur/etc/authn-k8s.conf ./dev/tmp/authn-k8s.conf
  cat << CONFIG >> ./dev/tmp/authn-k8s.conf
  RAILS_ENV=development
  RAILS_LOG_TO_STDOUT=true
CONFIG

  kubectl cp ./dev/tmp/authn-k8s.conf $pod_name:/opt/conjur/etc/authn-k8s.conf

  conjurcmd sv start nginx pg conjur
  conjurcmd /opt/conjur/evoke/bin/wait_for_conjur
}

function createSSLCertConfigMap() {
  echo 'Storing non-secret configuration data'

  ssl_certificate=$(conjurcmd cat /opt/conjur/etc/ssl/conjur.pem)

  # write out conjur ssl cert in configmap
  oc delete --ignore-not-found=true configmap conjurrc
  oc create configmap conjurrc \
    --from-literal=ssl-certificate="$ssl_certificate"
}

function loadConjurPolicies() {
  echo 'Loading the policies and data'

  conjurcmd conjur policy load --as-group security_admin /src/authn-k8s/dev/policies/conjur.${TEMPLATE_TAG}yml
  conjurcmd conjur-dev-service authn-k8s rake ca:initialize["conjur/authn-k8s/minikube"]

  password=$(openssl rand -hex 12)

  conjurcmd conjur variable values add inventory-db/password $password
}

function launchInventoryServices() {
  echo 'Launching inventory services'
  local service_count=4

  oc create -f dev/dev_inventory.${TEMPLATE_TAG}yaml
  oc create -f dev/dev_inventory_deployment_config.${TEMPLATE_TAG}yaml
  oc create -f dev/dev_inventory_pod.${TEMPLATE_TAG}yaml
  oc create -f dev/dev_inventory_unauthorized.${TEMPLATE_TAG}yaml

  if [[ "$K8S_VERSION" != "1.3" ]]; then  # stateful sets are k8s 1.5+ only
    oc create -f dev/dev_inventory_stateful.${TEMPLATE_TAG}yaml
    service_count=5
  fi

  wait_for_it 300 "oc describe po inventory | grep Status: | grep -c Running | grep -q $service_count"
}

function runTests() {
  echo 'Running tests'

  conjurcmd mkdir -p /src/authn-k8s/output
  echo "cd /src/authn-k8s && ./bin/cucumber K8S_VERSION=$K8S_VERSION PLATFORM=openshift --no-color --format pretty --format junit --out /src/authn-k8s/output ./features/cucumber/kubernetes" | conjurcmd -i bash
}

main
