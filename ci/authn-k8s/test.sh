#!/bin/bash -ex

# Given platform as a positional argument, runs authn-k8s tests against a live K8S cluster
# Expects environment variables to be passed in via summon

#!/bin/bash -euf
set -o pipefail

PLATFORM="$1"  # k8s platform

function main() {
  setupTestEnvironment $PLATFORM

  createNginxCert

  fetchSNICertificate

  buildDockerImages

  case "$PLATFORM" in
    gke)
      test_gke
      ;;
    openshift*)
      test_openshift
      ;;
    *)
      echo "'$PLATFORM' is not a supported test platform"
      exit 1
  esac
}

function setupTestEnvironment() {
  local platform="$1"

  export CONJUR_AUTHN_K8S_TEST_NAMESPACE="test-$(uuidgen | tr "[:upper:]" "[:lower:]")"

  case "$PLATFORM" in
    gke)
      export DOCKER_REGISTRY_PATH="gcr.io/$GCLOUD_PROJECT_NAME"
      ;;
    openshift*)
      export DOCKER_REGISTRY_PATH="$OPENSHIFT_REGISTRY_URL/$CONJUR_AUTHN_K8S_TEST_NAMESPACE"
      ;;
    *)
      echo "'$PLATFORM' is not a supported test platform"
      exit 1
  esac

  export PLATFORM

  export CONJUR_AUTHN_K8S_TAG="${DOCKER_REGISTRY_PATH}/conjur:authn-k8s-$CONJUR_AUTHN_K8S_TEST_NAMESPACE"
  export CONJUR_TEST_AUTHN_K8S_TAG="${DOCKER_REGISTRY_PATH}/conjur-test:authn-k8s-$CONJUR_AUTHN_K8S_TEST_NAMESPACE"
  export CONJUR_AUTHN_K8S_TESTER_TAG="${DOCKER_REGISTRY_PATH}/authn-k8s-tester:$CONJUR_AUTHN_K8S_TEST_NAMESPACE"

  export INVENTORY_BASE_TAG="${DOCKER_REGISTRY_PATH}/inventory_base:$CONJUR_AUTHN_K8S_TEST_NAMESPACE"
  export INVENTORY_TAG="${DOCKER_REGISTRY_PATH}/inventory:$CONJUR_AUTHN_K8S_TEST_NAMESPACE"

  export NGINX_TAG="${DOCKER_REGISTRY_PATH}/nginx:$CONJUR_AUTHN_K8S_TEST_NAMESPACE"
  export TINYPROXY_TAG="${DOCKER_REGISTRY_PATH}/tinyproxy:$CONJUR_AUTHN_K8S_TEST_NAMESPACE"

}

function createNginxCert() {
  docker pull svagi/openssl

  docker run --rm -i \
         -w /home -v $PWD/dev/tls:/home \
         svagi/openssl req\
         -x509 \
         -nodes \
         -days 365 \
         -newkey rsa:2048 \
         -config /home/tls.conf \
         -extensions v3_ca \
         -keyout nginx.key \
         -out nginx.crt
}

function fetchSNICertificate() {
  if [[ ! -z $SNI_FQDN ]]
  then
    docker run --rm -i \
           -w /home -v $PWD:/home \
           svagi/openssl s_client \
           -connect "$SNI_FQDN:$SNI_PORT" \
           -servername "$SNI_FQDN" > sni.out < /dev/null

    docker run --rm -i \
           -w /home -v $PWD:/home \
           svagi/openssl x509 \
           -in /home/sni.out \
           -out /home/sni.crt
  fi
}

function buildDockerImages() {
  conjur_version=$(echo "$(git rev-parse --short=8 HEAD)")
  DOCKER_REGISTRY_PATH="registry.tld"

  if ! docker image inspect "$DOCKER_REGISTRY_PATH/conjur:$conjur_version" > /dev/null 2>&1; then
    docker pull "$DOCKER_REGISTRY_PATH/conjur:$conjur_version"
  fi
  if ! docker image inspect "$DOCKER_REGISTRY_PATH/conjur-test:$conjur_version" > /dev/null 2>&1; then
    docker pull "$DOCKER_REGISTRY_PATH/conjur-test:$conjur_version"
  fi

  add_sni_cert_to_image "$DOCKER_REGISTRY_PATH/conjur:$conjur_version"
  add_sni_cert_to_image "$DOCKER_REGISTRY_PATH/conjur-test:$conjur_version"

  docker tag "$DOCKER_REGISTRY_PATH/conjur:$conjur_version" "$CONJUR_AUTHN_K8S_TAG"

  # cukes will be run from this image
  docker tag "$DOCKER_REGISTRY_PATH/conjur-test:$conjur_version" "$CONJUR_TEST_AUTHN_K8S_TAG"
  
  docker build -t "$INVENTORY_BASE_TAG" -f dev/Dockerfile.inventory_base dev
  docker build \
    --build-arg INVENTORY_BASE_TAG="$INVENTORY_BASE_TAG" \
    -t "$INVENTORY_TAG" \
    -f dev/Dockerfile.inventory \
    dev

  docker build -t "$NGINX_TAG" -f dev/Dockerfile.nginx dev
  docker build -t "$TINYPROXY_TAG" -f dev/Dockerfile.tinyproxy dev

  docker build --build-arg OPENSHIFT_CLI_URL="$OPENSHIFT_CLI_URL" \
    -t "$CONJUR_AUTHN_K8S_TESTER_TAG" -f dev/Dockerfile.test dev
}

function add_sni_cert_to_image() {
  image=$1

  if [ -f "sni.crt" ]
  then
    docker rm temp_container || true
    docker create --name temp_container "$image"
    docker cp sni.crt "temp_container:/opt/conjur/etc/ssl/ca/${sni_cert##*/}"
    docker commit temp_container "$image"
    docker rm temp_container
  fi
}

function test_gke() {
  docker run --rm \
    -e CUCUMBER_FILTER_TAGS \
    -e CONJUR_AUTHN_K8S_TAG \
    -e CONJUR_TEST_AUTHN_K8S_TAG \
    -e INVENTORY_TAG \
    -e INVENTORY_BASE_TAG \
    -e NGINX_TAG \
    -e CONJUR_AUTHN_K8S_TEST_NAMESPACE \
    -e GCLOUD_CLUSTER_NAME \
    -e GCLOUD_PROJECT_NAME \
    -e GCLOUD_SERVICE_KEY=/tmp$GCLOUD_SERVICE_KEY \
    -e GCLOUD_ZONE \
    -v $GCLOUD_SERVICE_KEY:/tmp$GCLOUD_SERVICE_KEY \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD":/src \
    -v "$PWD/../../cucumber/kubernetes:/cucumber/kubernetes" \
    $CONJUR_AUTHN_K8S_TESTER_TAG bash -c "./test_gke_entrypoint.sh"
}

function test_openshift() {
  docker run --rm \
    -e CUCUMBER_FILTER_TAGS \
    -e CONJUR_AUTHN_K8S_TAG \
    -e CONJUR_TEST_AUTHN_K8S_TAG \
    -e INVENTORY_TAG \
    -e INVENTORY_BASE_TAG \
    -e NGINX_TAG \
    -e TINYPROXY_TAG \
    -e CONJUR_AUTHN_K8S_TEST_NAMESPACE \
    -e PLATFORM \
    -e K8S_VERSION \
    -e OPENSHIFT_URL \
    -e OPENSHIFT_REGISTRY_URL \
    -e OPENSHIFT_INTERNAL_REGISTRY_URL \
    -e OPENSHIFT_USERNAME \
    -e OPENSHIFT_PASSWORD \
    -e OPENSHIFT_TOKEN \
    -e SNI_FQDN \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD":/src \
    $CONJUR_AUTHN_K8S_TESTER_TAG bash -c "./test_oc_entrypoint.sh"
}

main
