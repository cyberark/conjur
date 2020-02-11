#!/bin/bash -ex

AWS_PEM_FILE_LOCATION="<location of pem file to login to machine>"
USERNAME="<username of AWS machine>"
AWS_MACHINE="<AWS machine>"

pushd ../..
  . version_utils.sh
  CONJUR_IMAGE_VERSION="$(version_tag)"
  export CONJUR_IMAGE_VERSION

  ./build.sh
popd

# copy docker image into AWS machine
docker save -o ./conjur-image.tar conjur:$CONJUR_IMAGE_VERSION
scp -i "${AWS_PEM_FILE_LOCATION}" conjur-image.tar $USERNAME@$AWS_MACHINE:~/.

# copy authn-azure policies into AWS machine
scp -i "${AWS_PEM_FILE_LOCATION}" -r policies $USERNAME@$AWS_MACHINE:~/.

scp -i "${AWS_PEM_FILE_LOCATION}" setup-conjur.sh $USERNAME@$AWS_MACHINE:~/.

ssh -i "${AWS_PEM_FILE_LOCATION}" $USERNAME@$AWS_MACHINE CONJUR_IMAGE_VERSION="$CONJUR_IMAGE_VERSION" ./setup-conjur.sh