#!/bin/bash -ex

set -o pipefail

# Expects the following ENV vars to exist:
#
#    GCLOUD_CLUSTER_NAME
#    GCLOUD_ZONE
#    GCLOUD_PROJECT_NAME
#    GCLOUD_SERVICE_KEY
#    CONJUR_AUTHN_K8S_TEST_NAMESPACE
#    CONJUR_AUTHN_K8S_TAG
#    INVENTORY_TAG
#    INVENTORY_BASE_TAG
#    LOCAL_DEV_VOLUME
#
# PWD = /src (which is mapped via docker volume to ${WORKSPACE}/ci/test_suites/authenticators_k8s)

LOCAL_DEV_VOLUME=$(cat <<- ENDOFLINE
emptyDir: {}
ENDOFLINE
)
export LOCAL_DEV_VOLUME

function finish {
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]; then
    echo "Test PASSED!!!!"
  else
    echo "Test FAILED!!!! Displaying Kubernetes Resources"
    dump_pod_logs
  fi
  echo 'Finishing'
  echo '-----'

  {
    conjur_pod_name=$(retrieve_pod conjur-authn-k8s)
    if [[ "$conjur_pod_name" != "" ]]; then
      echo "Grabbing output from $conjur_pod_name"
      echo '-----'
      mkdir -p output
      kubectl cp "$conjur_pod_name:/opt/conjur-server/output" output

      echo "Logs from Conjur Pod $conjur_pod_name:"
      kubectl logs "$conjur_pod_name" > output/gke-authn-k8s-logs.txt

      # Rails.logger writes the logs to the environment log file
      kubectl exec "$conjur_pod_name" -- \
        bash -c "cat /opt/conjur-server/log/test.log" >> \
        output/gke-authn-k8s-logs.txt

      echo "Printing Logs from Conjur to the console"
      echo "==========================="
      cat output/gke-authn-k8s-logs.txt
      echo "==========================="

      echo "Killing conjur so that coverage report is written"
      # The container is kept alive using an infinite sleep in the at_exit hook
      # (see .simplecov) so that the kubectl cp below works.
      kubectl exec "${conjur_pod_name}" -- bash -c "pkill -f 'puma 6'"

      echo "Retrieving coverage report"
      kubectl cp \
        "$conjur_pod_name:/opt/conjur-server/coverage/.resultset.json" \
        output/simplecov-resultset-authnk8s-gke.json
    fi
  } || {
    echo "Logs could not be extracted from $conjur_pod_name"
    # So Jenkins artifact collection doesn't fail.
    touch output/gke-authn-k8s-logs.txt
  }

  {
    cucumber_pod_name=$(retrieve_pod cucumber-authn-k8s)
    if [[ "$conjur_pod_name" != "" ]]; then
      echo "Retrieving cucumber reports"
      kubectl cp \
        "$cucumber_pod_name:/opt/conjur-server/cucumber/authenticators_k8s/cucumber_results.json" \
        "/cucumber/authenticators_k8s/cucumber_results.json"

      kubectl cp \
        "$cucumber_pod_name:/opt/conjur-server/cucumber/authenticators_k8s/cucumber_results.html" \
        "/cucumber/authenticators_k8s/cucumber_results.html"

      kubectl cp \
        "$cucumber_pod_name:/opt/conjur-server/cucumber/authenticators_k8s/features/reports" \
        "/cucumber/authenticators_k8s/features/reports"
    fi
  } || {
    echo "Results could not be extracted from $cucumber_pod_name"
  }

  echo "Removing namespace $CONJUR_AUTHN_K8S_TEST_NAMESPACE"
  echo '-----'
  kubectl --ignore-not-found=true \
    delete namespace "$CONJUR_AUTHN_K8S_TEST_NAMESPACE"

  # We don't want errors when trying to delete something that's non-existent.
  set +e
  delete_image "$CONJUR_TEST_AUTHN_K8S_TAG"
  delete_image "$CONJUR_AUTHN_K8S_TAG"
  delete_image "$INVENTORY_TAG"
  delete_image "$INVENTORY_BASE_TAG"
  delete_image "$NGINX_TAG"
  set -e
}

function get_pod_names(){
    # get a list of pods except for Conjur
    kubectl get pods -o json \
    |jq -r '.items[].metadata.name' | grep -v conjur-authn-k8s
}

function get_pod_container_names(){
  pod="${1}"
  kubectl  get "pod/${pod}" -o json \
    |jq -r '.spec.containers[].name'
}

function dump_pod_logs(){
  kubectl get pods
  get_pod_names | while read -r podname; do
    get_pod_container_names "${podname}" | while read -r container_name; do
      echo -e "\n\n ======= Container Logs Pod:${podname} Container:${container_name} ======="
      kubectl logs "${podname}" --container "${container_name}" || true
      echo -e " ======= End of Container Logs Pod:${podname} Container:${container_name} ======="
    done
  done
}

trap finish EXIT

export TEMPLATE_TAG=gke.
export API_VERSION=rbac.authorization.k8s.io/v1

function main() {
  sourceFunctions
  renderResourceTemplates

  initialize_gke
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

function createNamespace() {
  # Attempt to clean up old namespaces. If it wasn't created within minutes or
  # seconds, we will attempt to delete it.
  old_namespaces=$(
    kubectl get namespaces | awk '$1 ~ /test-/ && $3 !~ /[m|s]/ { print $1; }'
  )

  if [ -n "${old_namespaces}" ]; then
    kubectl delete --ignore-not-found=true namespaces "${old_namespaces}"
  fi

  kubectl create namespace "$CONJUR_AUTHN_K8S_TEST_NAMESPACE"

  kubectl config set-context \
    "$(kubectl config current-context)" \
    "--namespace=$CONJUR_AUTHN_K8S_TEST_NAMESPACE"

  # Grant default service account permissions it needs for authn-k8s to:
  # 1) get + list various resources
  # 2) create + get pods/exec (to inject cert into app sidecar)
  kubectl apply -f dev/dev_conjur_authenticator_role.${TEMPLATE_TAG}yaml
  wait_for_it 1 "kubectl get clusterrole conjur-authenticator"
  kubectl create \
    -f dev/dev_conjur_authenticator_role_binding.${TEMPLATE_TAG}yaml
}

function pushDockerImages() {
  docker push "$CONJUR_AUTHN_K8S_TAG"
  docker push "$CONJUR_TEST_AUTHN_K8S_TAG"
  docker push "$INVENTORY_TAG"
  docker push "$INVENTORY_BASE_TAG"
  docker push "$NGINX_TAG"
  docker push "$TINYPROXY_TAG"
}

function launchConjurMaster() {
  echo 'Launching Conjur master service'

  run_conjur_master "dev_conjur"

  API_KEY=$(
    kubectl exec "$conjur_pod" -- \
      conjurctl account create cucumber | tail -n 1 | awk '{ print $NF }'
  )
  export API_KEY
}

function copyNginxSSLCert() {
  nginx_pod=$(retrieve_pod nginx-authn-k8s)
  cucumber_pod=$(retrieve_pod cucumber-authn-k8s)
  kubectl wait --for=condition=Ready "pod/$nginx_pod" --timeout=5m
  kubectl wait --for=condition=Ready "pod/$cucumber_pod" --timeout=5m

  kubectl cp "$nginx_pod:/etc/nginx/nginx.crt" ./nginx.crt
  kubectl cp ./nginx.crt "$cucumber_pod:/opt/conjur-server/nginx.crt"
}

function copyConjurPolicies() {
  cli_pod=$(retrieve_pod conjur-cli)
  kubectl wait --for=condition=Ready "pod/$cli_pod" --timeout=5m

  kubectl cp ./dev/policies "$cli_pod:/policies"
}

function loadConjurPolicies() {
  echo 'Loading the policies and data'

  # kubectl wait not needed -- already done in copyConjurPolicies.
  cli_pod=$(retrieve_pod conjur-cli)

  kubectl exec "$cli_pod" -- conjur init -u conjur -a cucumber
  sleep 5
  kubectl exec "$cli_pod" -- conjur authn login -u admin -p "$API_KEY"

  # load policies
  wait_for_it 300 "kubectl exec $cli_pod -- \
    conjur policy load root /policies/policy.${TEMPLATE_TAG}yml"

  # init ca certs
  # kubectl wait not needed -- already done in launchConjurMaster.
  kubectl exec "$(retrieve_pod conjur-authn-k8s)" -- \
    rake authn_k8s:ca_init["conjur/authn-k8s/minikube"]
}

function launchInventoryServices() {
  echo 'Launching inventory services'

  applyInventoryFile "inventory"
  applyInventoryFile "inventory_stateful"
  applyInventoryFile "inventory_unauthorized"
  # This yaml file has 2 pods
  applyInventoryFile "inventory_pod"

  wait_for_it 300 "kubectl describe po inventory | \
    grep Status: | grep -c Running | grep -q 5"
}

function applyInventoryFile() {
  filename=$1

  sed -e "s#{{ INVENTORY_TAG }}#$INVENTORY_TAG#g" "dev/dev_$filename.${TEMPLATE_TAG}yaml" |
  sed -e "s#{{ CONJUR_AUTHN_K8S_TEST_NAMESPACE }}#$CONJUR_AUTHN_K8S_TEST_NAMESPACE#g" |
  sed -e "s#{{ INVENTORY_BASE_TAG }}#$INVENTORY_BASE_TAG#g" |
  kubectl apply -f -
}

function runTests() {
  echo 'Running tests'

  conjurcmd mkdir -p /opt/conjur-server/output

  # THE INFRAPOOL_CUCUMBER_FILTER_TAGS environment variable is not natively
  # implemented in cucumber-ruby, so we pass it as a CLI argument
  # if the variable is set.
  local cucumber_tags_arg
  if [[ -n "$INFRAPOOL_CUCUMBER_FILTER_TAGS" ]]; then
    cucumber_tags_arg="--tags \"$INFRAPOOL_CUCUMBER_FILTER_TAGS\""
  fi

  # Run standard k8s authenticator tests
  run_cucumber "--tags 'not @skip' --tags 'not @k8s_skip' --tags 'not @sni_fails' --tags 'not @sni_success' $cucumber_tags_arg"

  # Run k8s authenticator tests with an HTTP proxy
  run_conjur_master "dev_conjur_http_proxy" --disable-k8s-api-dns
  run_cucumber "--tags 'not @skip' --tags 'not @k8s_skip' --tags '@http_proxy'"
}

retrieve_pod() {
  # Return the most recent pod name
  kubectl get pods \
    -l "app=$1" \
    --field-selector=status.phase!=Terminating \
    --sort-by=.metadata.creationTimestamp \
    --no-headers |
      tail -n 1 |
      awk '{print $1}'
}

function run_conjur_master() {
  filename=$1; shift

  sed -e "s#{{ CONJUR_AUTHN_K8S_TAG }}#$CONJUR_AUTHN_K8S_TAG#g" "dev/$filename.${TEMPLATE_TAG}yaml" |
    sed -e "s#{{ CONJUR_TEST_AUTHN_K8S_TAG }}#$CONJUR_TEST_AUTHN_K8S_TAG#g" |
    sed -e "s#{{ NGINX_TAG }}#$NGINX_TAG#g" |
    sed -e "s#{{ DATA_KEY }}#$DATA_KEY#g" |
    sed -e "s#{{ CONJUR_AUTHN_K8S_TEST_NAMESPACE }}#$CONJUR_AUTHN_K8S_TEST_NAMESPACE#g" |
    kubectl apply -f -

  # Turn off -e since we expect failures when retrieving pod before it's ready.
  set +e

  local num_tries=0
  local max_tries=20
  local pod_retrieved=false

  while [[ $num_tries -lt $max_tries ]]; do
    echo "Try $num_tries of $max_tries to retrieve pod conjur-authn-k8s..."

    if conjur_pod=$(retrieve_pod conjur-authn-k8s); then
      echo "Success!"
      pod_retrieved=true
      break
    fi

    sleep 5
    (( num_tries++ ))
  done

  if [[ $pod_retrieved != true ]]; then
    echo "Unable to retrieve pod.  Exiting..."
    exit 1
  fi

  set -e

  kubectl wait --for=condition=Ready "pod/$conjur_pod" --timeout=5m

  # wait for the 'conjurctl server' entrypoint to finish
  local wait_command="while ! curl --silent --head --fail \
    localhost:80 > /dev/null; do sleep 1; done"
  kubectl exec "$conjur_pod" -- bash -c "$wait_command"

  # Handle flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --disable-k8s-api-dns)
        # Add a host entry to blackhole the kubernetes API endpoint
        kubectl exec "$conjur_pod" -- \
          bash -c "echo '0.0.0.0 kubernetes.default.svc' >> /etc/hosts"
        shift ;;
      *)
        echo "Unknown option: $1"
    esac
  done
}

function run_cucumber() {
  cucumber_args=$1
  echo "./bin/cucumber \
    K8S_VERSION=1.7 \
    PLATFORM=kubernetes \
    --no-color --format pretty --strict \
    --format json --out \"./cucumber/authenticators_k8s/cucumber_results.json\" \
    --format html --out \"./cucumber/authenticators_k8s/cucumber_results.html\" \
    --format junit --out \"./cucumber/authenticators_k8s/features/reports\" \
    -r ./cucumber/authenticators_k8s/features/step_definitions/ \
    -r ./cucumber/authenticators_k8s/features/support/world.rb \
    -r ./cucumber/authenticators_k8s/features/support/hooks.rb \
    -r ./cucumber/authenticators_k8s/features/support/conjur_token.rb \
    $cucumber_args ./cucumber/authenticators_k8s/features" | cucumbercmd -i bash
}

main
