#!/bin/bash -ex

docker-compose build apidocs # builds conjur-apidocs image
docker run --rm conjur-apidocs > docs/_includes/api.html

docker-compose run --rm  \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e POSSUM_WEB_BUCKET -e POSSUM_WEB_CFG_BUCKET \
  -e POSSUM_WEB_USER -e POSSUM_WEB_PASSWORD \
  -e CPANEL_URL \
  docs bash -ec '
mkdir -p /output
jekyll build --plugins docs/_plugins --source docs --destination /output/_site

echo "${POSSUM_WEB_USER}:$(openssl passwd -apr1 ${POSSUM_WEB_PASSWORD})" | aws s3 cp - s3://${POSSUM_WEB_CFG_BUCKET}/htpasswd

aws s3 sync --delete /output/_site s3://${POSSUM_WEB_BUCKET}
'
