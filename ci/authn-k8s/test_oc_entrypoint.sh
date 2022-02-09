#!/bin/bash -ex

set -o pipefail

# expects
# PLATFORM K8S_VERSION OPENSHIFT_USERNAME OPENSHIFT_PASSWORD
# CONJUR_AUTHN_K8S_TEST_NAMESPACE CONJUR_AUTHN_K8S_TAG INVENTORY_TAG INVENTORY_BASE_TAG
# LOCAL_DEV_VOLUME
# to exist

export LOCAL_DEV_VOLUME=$(cat <<- ENDOFLINE
emptyDir: {}
ENDOFLINE
)

function finish {
  echo 'Finishing'
  echo '-----'

  echo "Removing namespace $CONJUR_AUTHN_K8S_TEST_NAMESPACE"
  echo '-----'

  sleep 5

  oc adm policy remove-scc-from-user anyuid -z default
  oc --ignore-not-found=true delete project $CONJUR_AUTHN_K8S_TEST_NAMESPACE
}

export TEMPLATE_TAG="$PLATFORM."
export API_VERSION=v1

function main() {
  sourceFunctions
  renderResourceTemplates

  initialize_oc
  createNamespace

  pushDockerImages

  launchConjurMaster
  copyNginxSSLCert
  copyConjurPolicies
  loadConjurPolicies
  launchInventoryServices

  resetLogFile
  runTests
  finish
}

function resetLogFile() {
  cat /dev/null > "output/$PLATFORM-authn-k8s-logs.txt"
}

function printLogs() {
  {
    pod_name=$(retrieve_pod conjur-authn-k8s)
    if [[ "$pod_name" != "" ]]; then
      echo "Grabbing output from $pod_name"
      echo '-----'
      mkdir -p output
      kubectl cp $pod_name:/src/authn-k8s/output output

      echo "Logs from Conjur Pod $pod_name:"
      oc logs "$pod_name" >> "output/$PLATFORM-authn-k8s-logs.txt"

      # Rails.logger writes the logs to the environment log file
      oc exec "$pod_name" -- bash -c "cat /opt/conjur-server/log/test.log" >> "output/$PLATFORM-authn-k8s-logs.txt"

      echo "Printing Logs from Conjur to the console"
      echo "==========================="
      cat "output/$PLATFORM-authn-k8s-logs.txt"
      echo "==========================="
    fi
  } || {
    echo "Logs could not be extracted from $pod_name"
    touch "output/$PLATFORM-authn-k8s-logs.txt"  # so Jenkins artifact collection doesn't fail
  }
}

function copyNginxSSLCert() {
  nginx_pod=$(retrieve_pod nginx-authn-k8s)
  cucumber_pod=$(retrieve_pod cucumber-authn-k8s)
  kubectl wait --for=condition=Ready "pod/$nginx_pod" --timeout=5m
  kubectl wait --for=condition=Ready "pod/$cucumber_pod" --timeout=5m

  kubectl cp "$nginx_pod:/etc/nginx/nginx.crt" ./nginx.crt
  kubectl cp ./nginx.crt "$cucumber_pod:/opt/conjur-server/nginx.crt"
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
  docker push "$INVENTORY_BASE_TAG"
  docker push "$CONJUR_AUTHN_K8S_TAG"
  docker push "$CONJUR_TEST_AUTHN_K8S_TAG"
  docker push "$INVENTORY_TAG"
  docker push "$NGINX_TAG"
  docker push "$TINYPROXY_TAG"
}

function launchConjurMaster() {
  echo 'Launching Conjur master service'

  DATA_KEY=$(openssl rand -base64 32)
  export DATA_KEY="$DATA_KEY"
  run_conjur_master "dev_conjur"

  export API_KEY=$(oc exec $conjur_pod -- conjurctl account create cucumber | tail -n 1 | awk '{ print $NF }')
  echo "$API_KEY"
}

function createSSLCertConfigMap() {
  echo 'Storing non-secret configuration data'

  ssl_certificate=$(conjurcmd cat /opt/conjur/etc/ssl/conjur.pem)

  # write out conjur ssl cert in configmap
  oc delete --ignore-not-found=true configmap conjurrc
  oc create configmap conjurrc \
    --from-literal=ssl-certificate="$ssl_certificate"
}

function copyConjurPolicies() {
  cli_pod=$(retrieve_pod conjur-cli)

  oc exec $cli_pod -- mkdir /policies
  oc rsync ./dev/policies $cli_pod:/
}

function loadConjurPolicies() {
  echo 'Loading the policies and data'

  cli_pod=$(retrieve_pod conjur-cli)

  oc exec $cli_pod -- conjur init -u conjur -a cucumber
  sleep 5
  oc exec $cli_pod -- conjur authn login -u admin -p $API_KEY

  wait_for_it 300 "oc exec $cli_pod -- conjur policy load root /policies/policy.${TEMPLATE_TAG}yml"

  # init ca certs
  conjur_pod=$(retrieve_pod conjur-authn-k8s)
  oc exec $conjur_pod -- rake authn_k8s:ca_init["conjur/authn-k8s/minikube"]
}

function launchInventoryServices() {
  echo 'Launching inventory services'
  local service_count=5

  applyInventoryFile "inventory"
  applyInventoryFile "inventory_deployment_config"
  applyInventoryFile "inventory_unauthorized"
  # This yaml file has 2 pods
  applyInventoryFile "inventory_pod"

  if [[ "$K8S_VERSION" != "1.3" ]]; then  # stateful sets are k8s 1.5+ only
    applyInventoryFile "inventory_stateful"
    service_count=6
  fi

  #oc describe po inventory | grep Status: | grep -vc Running | greq -q 0
  sleep 10
  oc delete pod inventory-no-ssl-dir
  applyInventoryFile "inventory_pod"

  wait_for_it 420 "oc describe po inventory | grep Status: | grep -c Running | grep -q $service_count"
}

function applyInventoryFile() {
  filename=$1

  INVENTORY_TAG=$(echo $INVENTORY_TAG | sed "s/$OPENSHIFT_REGISTRY_URL/$OPENSHIFT_INTERNAL_REGISTRY_URL/")
  CONJUR_AUTHN_K8S_TEST_NAMESPACE=$(echo $CONJUR_AUTHN_K8S_TEST_NAMESPACE | sed "s/$OPENSHIFT_REGISTRY_URL/$OPENSHIFT_INTERNAL_REGISTRY_URL/")
  INVENTORY_BASE_TAG=$(echo $INVENTORY_BASE_TAG | sed "s/$OPENSHIFT_REGISTRY_URL/$OPENSHIFT_INTERNAL_REGISTRY_URL/")

  sed -e "s#{{ INVENTORY_TAG }}#$INVENTORY_TAG#g" "dev/dev_$filename.${TEMPLATE_TAG}yaml" |
  sed -e "s#{{ CONJUR_AUTHN_K8S_TEST_NAMESPACE }}#$CONJUR_AUTHN_K8S_TEST_NAMESPACE#g" |
  sed -e "s#{{ INVENTORY_BASE_TAG }}#$INVENTORY_BASE_TAG#g" |
  oc apply -f -
}


function runTests() {
  echo 'Running tests'

  conjurcmd mkdir -p /opt/conjur-server/output

  run_cucumber "~@skip --tags ~@k8s_skip --tags ~@sni_fails --tags ~@sni_success --tags ~@http_proxy"

  printLogs

  conjur_pod=$(retrieve_pod conjur-authn-k8s)
  api_server_ip=$(kubectl exec "$conjur_pod" -- sh -c 'echo $KUBERNETES_SERVICE_HOST')

  run_conjur_master "dev_conjur_sni" "$api_server_ip" "api-other.test.com"

  run_cucumber "@sni_fails"

  printLogs

  run_conjur_master "dev_conjur_sni" "$api_server_ip" "$SNI_FQDN"

  run_cucumber "@sni_success"

  printLogs

  run_conjur_master "dev_conjur_http_proxy"

  run_cucumber "@http_proxy"

  printLogs
}

function retrieve_pod() {
  oc get pods -l app=$1 -o=jsonpath='{.items[].metadata.name}'
}

function run_conjur_master() {
  filename=$1
  api_server_ip=$2
  api_fqdn=$3

  CONJUR_AUTHN_K8S_TAG=$(echo $CONJUR_AUTHN_K8S_TAG | sed "s/$OPENSHIFT_REGISTRY_URL/$OPENSHIFT_INTERNAL_REGISTRY_URL/")
  CONJUR_TEST_AUTHN_K8S_TAG=$(echo $CONJUR_TEST_AUTHN_K8S_TAG | sed "s/$OPENSHIFT_REGISTRY_URL/$OPENSHIFT_INTERNAL_REGISTRY_URL/")
  NGINX_TAG=$(echo $NGINX_TAG | sed "s/$OPENSHIFT_REGISTRY_URL/$OPENSHIFT_INTERNAL_REGISTRY_URL/")

  sed -e "s#{{ CONJUR_AUTHN_K8S_TAG }}#$CONJUR_AUTHN_K8S_TAG#g" "dev/$filename.${TEMPLATE_TAG}yaml" |
    sed -e "s#{{ CONJUR_TEST_AUTHN_K8S_TAG }}#$CONJUR_TEST_AUTHN_K8S_TAG#g" |
    sed -e "s#{{ NGINX_TAG }}#$NGINX_TAG#g" |
    sed -e "s#{{ DATA_KEY }}#$DATA_KEY#g" |
    sed -e "s#{{ CONJUR_AUTHN_K8S_TEST_NAMESPACE }}#$CONJUR_AUTHN_K8S_TEST_NAMESPACE#g" |
    sed -e "s#{{ KUBERNETES_SERVICE_HOST }}#$api_server_ip#g" |
    sed -e "s#{{ KUBERNETES_API_FQDN }}#$api_fqdn#g" |
    oc apply -f -

  sleep 5

  conjur_pod=$(retrieve_pod conjur-authn-k8s)

  wait_for_it 300 "oc describe po $conjur_pod | grep Status: | grep -q Running"

  # wait for the 'conjurctl server' entrypoint to finish
  local wait_command="while ! curl -sI localhost:80 > /dev/null; do sleep 1; done"
  oc exec $conjur_pod -- bash -c "$wait_command"
}

function run_cucumber() {
  tags=$1
  echo "./bin/cucumber \
    K8S_VERSION=$K8S_VERSION \
    PLATFORM=openshift \
    --no-color --format pretty --format junit \
    --out /opt/conjur-server/output \
    -r ./cucumber/kubernetes/features/step_definitions/ \
    -r ./cucumber/kubernetes/features/support/world.rb \
    -r ./cucumber/kubernetes/features/support/hooks.rb \
    -r ./cucumber/kubernetes/features/support/conjur_token.rb \
    --tags $tags ./cucumber/kubernetes/features" | cucumbercmd -i bash || true
}

main
