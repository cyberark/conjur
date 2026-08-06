# conjur_csi_provider POC

This POC provides a basic implemtation of a provider for Secret Store CSI Driver.

Here are the steps install and setup a Kubernetes in Docker cluster

```sh
# Install kind
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create kind cluster
kind create cluster
```

Here are the steps to deploy and validate the provider:
```sh
# Create namespace
kubectl create ns csi
# Switch to namespace
kubectl config set-context --current --namespace=csi

# Deploy Secrets Store CSI Driver
CSI_DRIVER_VERSION=1.3.2
helm install secrets-store-csi-driver secrets-store-csi-driver \
		--repo https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts --version=${CSI_DRIVER_VERSION} \
		--wait --timeout=5m \
		--namespace=csi \
		--set linux.image.pullPolicy="IfNotPresent" \
		--set syncSecret.enabled=true \
		--set tokenRequests[0].audience="conjur"

# Build container image for conjur-csi-provider 
docker build -f - -t conjur-csi-provider . <<EOF
FROM golang:1.20

WORKDIR /app
ADD . .
RUN go build -o /conjur-csi-provider

ENTRYPOINT ["/conjur-csi-provider"]
EOF

# Build the CLI
docker build -f - -t conjur-cli . <<EOF
FROM golang:latest

COPY --from=cyberark/conjur-cli:8 /usr/local/bin/conjur /usr/local/bin/conjur

ENTRYPOINT ["/usr/local/bin/conjur"]
EOF


# Load the images
kind load docker-image conjur-cli:latest
kind load docker-image conjur-csi-provider:latest

# Deploy Conjur
CONJUR_NAMESPACE=conjur
CONJUR_DATA_KEY="$(docker run --rm cyberark/conjur data-key generate)"
HELM_RELEASE=conjur
VERSION=2.0.6

# Create Conjur namespace
kubectl create namespace "$CONJUR_NAMESPACE"

# Install Conjur
helm install \
   -n "$CONJUR_NAMESPACE" \
   --set "dataKey=$CONJUR_DATA_KEY" \
   --set logLevel="debug" \
   --set "authenticators=authn\,authn-jwt/kube" \
   "$HELM_RELEASE" \
   https://github.com/cyberark/conjur-oss-helm-chart/releases/download/v$VERSION/conjur-oss-$VERSION.tgz

# Create Conjur account
ls -la ./created_account > /dev/null 2>&1 > || kubectl exec --namespace conjur \
            deployment/conjur-conjur-oss  \
            --container=conjur-oss \
            -- conjurctl account create "default" > created_account
cat ./created_account

# Run Conjur CLI
kubectl run conjur-cli-pod --image=conjur-cli:latest --image-pull-policy=Never --namespace=conjur --command -- sleep infinity

# Setup authenticator and secrets using Conjur CLI

# Create files
mkdir -p ./files
# Create policy
cat << EOL > ./files/policy.yml
---

- !host

- !host 
  id: kubernetes/applications/system:serviceaccount:default:default
  annotations:
    authn-jwt/kube/kubernetes.io/namespace: default

- !host 
  id: host1
  annotations:
    authn-jwt/kube/kubernetes.io/namespace: csi
    authn-jwt/kube/kubernetes.io/serviceaccount/name: default

- !variable secretVar

- !permit
  # Give permissions to the human user to update the secret and fetch the secret.
  role: !host /host1
  privileges: [read, update, execute]
  resource: !variable secretVar

# This policy defines a JWT authenticator to be used with Kubernetis cluster
- !policy
  id: conjur/authn-jwt/kube
  body:
  - !webservice

  # Uncomment one of following variables depending on the public availability
  # of the Service Account Issuer Discovery service in Kubernetes 
  # If the service is publicly available, uncomment 'jwks-uri'.
  # If the service is not available, uncomment 'public-keys'

  # - !variable
  #   id: jwks-uri

  - !variable
    id: public-keys

  # This variable tells Conjur which claim in the JWT to use to determine the conjur host identity.
  # - !variable
  #   id: token-app-property # Most likely set to "sub" for Kubernetes

  # This variable is used with token-app-property. This variable will hold the conjur policy path that contains the conjur host identity found by looking at the claim entered in token-app-property.
  # - !variable
  #   id: identity-path

  # Uncomment ca-cert if the JWKS website cert isn't trusted by conjur

  # - !variable
  #   id: ca-cert

  # This variable contains what "iss" in the JWT.
  - !variable
    id: issuer
  
  # This variable contains what "aud" is the JWT.
  # - !variable
  #   id: audience
  
  - !permit
    role: !host /kubernetes/applications/system:serviceaccount:default:default
    privilege: [ read, authenticate ]
    resource: !webservice

  - !permit
    role: !host /host1
    privilege: [ read, authenticate ]
    resource: !webservice
EOL

# Get values required by authn-jwt authenticator and store to files
kubectl get --raw /.well-known/openid-configuration | jq -r .issuer > ./files/issuer
echo '{"type": "jwks", "value": '$(kubectl get --raw /openid/v1/jwks)' }' > ./files/jwks

# Copy files into CLI container
kubectl -n "${CONJUR_NAMESPACE}" cp ./files conjur-cli-pod:/files -c conjur-cli-pod

# Exec into CLI container
kubectl -n "${CONJUR_NAMESPACE}" exec -it conjur-cli-pod bash

# Run this script manually
echo "
# Initialise CLI and login
conjur init -u https://conjur-conjur-oss.conjur.svc.cluster.local -a "default" --self-signed
conjur login -i admin

# Apply policy
conjur policy replace -b root -f ./policy.yml

# Inspect resources
# conjur list
# conjur resource show default:host:host1

# Set secret value
conjur variable set -i secretVar -v something-super-secret

# Set variable values on authenticator
conjur variable set -i conjur/authn-jwt/kube/public-keys -v $(cat /files/jwks)
conjur variable set -i conjur/authn-jwt/kube/issuer -v $(cat /files/issuer)

# Validate authenticator
curl -v -k --request POST 'https://conjur-conjur-oss.conjur.svc.cluster.local/authn-jwt/kube/default/host%2Fhost1/authenticate' --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept-Encoding: base64' --data-urlencode 'jwt='$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
"

# Remove app and provider
# kubectl delete pod --force app conjur-csi-provider

# Deploy the provider
kubectl apply -f ./manifest/conjur-csi-provider.yml

# Make sure the provider is up and running
kubectl logs conjur-csi-provider
# 2023/06/21 18:07:07 Conjur CSI provider server started. Socket path: /var/run/secrets-store-csi-providers/conjur.sock

# Deploy the app
kubectl apply -f ./manifest/app.yml

# Check that the app is up and running
kubectl describe pod app
#   ...
# 
#   Type    Reason     Age    From               Message
#   ----    ------     ----   ----               -------
#   Normal  Scheduled  6m43s  default-scheduler  Successfully assigned csi/app to kind-control-plane
#   Normal  Pulling    6m41s  kubelet            Pulling image "golang:latest"
#   Normal  Pulled     6m38s  kubelet            Successfully pulled image "golang:latest" in 2.4410207s (2.4410285s including waiting)
#   Normal  Created    6m38s  kubelet            Created container app
#   Normal  Started    6m37s  kubelet            Started container app

# Check the logs the provider again to see the mount request
kubectl logs -f conjur-csi-provider

# Check the contents of the secrets-store directory
kubectl exec -it app -- ls -la /mnt/secrets-store
```
