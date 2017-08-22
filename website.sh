#!/bin/bash -ex

docker build -t conjur-web -f docs/Dockerfile .

docker run -i -v $PWD:/opt/conjur --rm  \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e POSSUM_WEB_BUCKET -e POSSUM_WEB_CFG_BUCKET \
  -e POSSUM_WEB_USER -e POSSUM_WEB_PASSWORD \
  -e CPANEL_URL \
  conjur-web bash -ec '
mkdir /output

/node_modules/.bin/aglio --theme-template apidocs/templates/index.jade --theme-style apidocs/templates/css/layout-conjur.less -i apidocs/src/api.md -o docs/_includes/api.html

cd docs

jekyll build --destination /output/_site

echo "${POSSUM_WEB_USER}:$(openssl passwd -apr1 ${POSSUM_WEB_PASSWORD})" | aws s3 cp - s3://${POSSUM_WEB_CFG_BUCKET}/htpasswd

aws s3 sync --delete /output/_site s3://${POSSUM_WEB_BUCKET}
'
