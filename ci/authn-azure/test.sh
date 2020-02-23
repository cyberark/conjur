#!/bin/bash
set -exuo pipefail

# TODO: get these dynamically
AWS_PEM_FILE_LOCATION="<location of pem file to login to machine>"
AWS_MACHINE_USERNAME="<username of AWS machine>"
CONJUR_SERVER_DNS="<DNS of Conjur server machine>"

AZURE_VM_USERNAME="<username of Azure VM>"
AZURE_VM_IP="<IP address of Azure VM>"

# Build Conjur image
pushd ../..
  . version_utils.sh
  conjur_image_version="$(version_tag)"

  ./build.sh
popd

# Copy docker image into AWS machine
docker save -o ./conjur-image.tar conjur:$conjur_image_version
tar -czvf conjur-image.tar.gz conjur-image.tar
scp -i "${AWS_PEM_FILE_LOCATION}" conjur-image.tar.gz $AWS_MACHINE_USERNAME@$CONJUR_SERVER_DNS:~/.

# Copy authn-azure policies into AWS machine
scp -i "${AWS_PEM_FILE_LOCATION}" -r policies $AWS_MACHINE_USERNAME@$CONJUR_SERVER_DNS:~/.

scp -i "${AWS_PEM_FILE_LOCATION}" setup-conjur.sh $AWS_MACHINE_USERNAME@$CONJUR_SERVER_DNS:~/.
ssh -i "${AWS_PEM_FILE_LOCATION}" $AWS_MACHINE_USERNAME@$CONJUR_SERVER_DNS CONJUR_IMAGE_VERSION="$conjur_image_version" ./setup-conjur.sh

scp run-authn-azure.sh $AZURE_VM_USERNAME@$AZURE_VM_IP:~/.
ssh $AZURE_VM_USERNAME@$AZURE_VM_IP CONJUR_SERVER_DNS="$CONJUR_SERVER_DNS" ./run-authn-azure.sh
