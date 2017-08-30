#!/bin/bash -ex

docker-compose run --rm apidocs > docs/_includes/api.html

docker-compose run --rm  \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e POSSUM_WEB_BUCKET -e POSSUM_WEB_CFG_BUCKET \
  -e POSSUM_WEB_USER -e POSSUM_WEB_PASSWORD \
  -e CPANEL_URL \
  docs bash -ec '
mkdir /output
jekyll build --destination /output/_site

echo "${POSSUM_WEB_USER}:$(openssl passwd -apr1 ${POSSUM_WEB_PASSWORD})" | aws s3 cp - s3://${POSSUM_WEB_CFG_BUCKET}/htpasswd

aws s3 sync --delete /output/_site s3://${POSSUM_WEB_BUCKET}
'
