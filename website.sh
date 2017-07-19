#!/bin/bash -ex

docker build -t possum-web -f docs/Dockerfile .

docker run -i -v $PWD:/opt/conjur --rm  \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e POSSUM_WEB_BUCKET -e POSSUM_WEB_CFG_BUCKET \
  -e POSSUM_WEB_USER -e POSSUM_WEB_PASSWORD \
  possum-web bash -ec '
mkdir /output
jekyll build --source docs --destination /output/_site

/node_modules/.bin/aglio -i apidocs/src/api.md -o /output/_site/apidocs.html

echo "${POSSUM_WEB_USER}:$(openssl passwd -apr1 ${POSSUM_WEB_PASSWORD})" | aws s3 cp - s3://${POSSUM_WEB_CFG_BUCKET}/htpasswd

aws s3 sync /output/_site s3://${POSSUM_WEB_BUCKET}
'
