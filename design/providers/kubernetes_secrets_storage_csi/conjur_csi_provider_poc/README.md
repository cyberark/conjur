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
FROM golang:1.17-alpine AS build

WORKDIR /app
ADD . .
RUN go build -o conjur-csi-provider

FROM alpine:latest

WORKDIR /app
COPY --from=build /app/conjur-csi-provider .

ENTRYPOINT ["./conjur-csi-provider"]
EOF

# Load the image
kind load docker-image conjur-csi-provider:latest

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
