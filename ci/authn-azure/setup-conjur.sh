#!/bin/bash -ex

sudo docker load -i conjur-image.tar

# Remove old containers if they are up
if [[ -d "conjur-quickstart" ]]
then
  pushd conjur-quickstart
  sudo docker-compose down -v
  popd
fi

rm -rf conjur-quickstart
git clone --single-branch --branch local-conjur-image https://github.com/cyberark/conjur-quickstart.git
cd conjur-quickstart
sudo docker-compose down -v

sed "s#{{ CONJUR_IMAGE_VERSION }}#$CONJUR_IMAGE_VERSION#g" ./Dockerfile.template > ./Dockerfile
sudo docker-compose pull
sudo docker-compose build
sudo docker-compose run --no-deps --rm conjur data-key generate > data_key

export CONJUR_DATA_KEY="$(< data_key)"
echo "Generated CONJUR_DATA_KEY $CONJUR_DATA_KEY"

# TODO: Make it work without sed. docker-compose should take the host's env var if it is not set but it doesn't work
sed "s#{{ CONJUR_DATA_KEY }}#${CONJUR_DATA_KEY}#" ./docker-compose.yml.template > ./docker-compose.yml

sudo docker-compose up -d

# Wait for all components to be up before we create the account
sleep 5
sudo docker-compose exec -T conjur conjurctl account create cucumber

sudo docker-compose exec -T client conjur init -u conjur -a cucumber
ADMIN_API_KEY=$(sudo docker-compose exec -T conjur conjurctl role retrieve-key cucumber:user:admin | tr -d '\r')
sudo docker-compose exec -T client conjur authn login -u admin -p $ADMIN_API_KEY

# Copy the policy files into the directory that is volumed into the client
cp ../policies/* conf/policy/

sudo docker-compose exec -T client conjur policy load root policy/authn-azure.yml

AZURE_PROVIDER_URI="https://some-provider.com"
sudo docker-compose exec -T client conjur variable values add conjur/authn-azure/test/provider-uri $AZURE_PROVIDER_URI

sudo docker-compose exec -T client conjur policy load root policy/azure-hosts.yml

sudo docker-compose exec -T client conjur policy load root policy/test-secrets.yml
sudo docker-compose exec -T client conjur variable values add secrets/test-variable test-secret
