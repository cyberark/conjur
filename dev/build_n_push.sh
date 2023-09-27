#Builds and deploys to ECR the mgmt-conjur-dev-repository-conjur image in region us-east-2
#Usage from conjur folder run ./dev/build_n_push.sh <version>. aws sso login is required

VERSION=$1

bundle config set --local without test:development
AWS_PROFILE=dev aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 238637036211.dkr.ecr.us-east-2.amazonaws.com
docker rmi -f 238637036211.dkr.ecr.us-east-2.amazonaws.com/mgmt-conjur-dev-repository-conjur:$VERSION
docker build -t mgmt-conjur-dev-repository-conjur .
docker tag mgmt-conjur-dev-repository-conjur:latest 238637036211.dkr.ecr.us-east-2.amazonaws.com/mgmt-conjur-dev-repository-conjur:$VERSION
AWS_PROFILE=dev aws ecr batch-delete-image --repository-name mgmt-conjur-dev-repository-conjur --region us-east-2 --image-ids imageTag=$VERSION
docker push 238637036211.dkr.ecr.us-east-2.amazonaws.com/mgmt-conjur-dev-repository-conjur:$VERSION

bundle config unset --local without