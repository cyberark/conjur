#!/bin/bash -ex

. git_tag.sh

TAG="$(git_tag)"

function finish {
	docker rm -f $pg_cid
	docker rm -f $server_cid
}
trap finish EXIT

export CONJUR_DATA_KEY="$(docker run --rm conjur:$TAG data-key generate)"

pg_cid=$(docker run -d postgres:9.3)

mkdir -p spec/reports
mkdir -p cucumber/api/features/reports
mkdir -p cucumber/policy/features/reports

server_cid=$(docker run -d \
	--link $pg_cid:pg \
	-v $PWD/run/authn-local:/run/authn-local \
	-e DATABASE_URL=postgres://postgres@pg/postgres \
	-e RAILS_ENV=test \
	conjur:$TAG server)

cat << "TEST" | docker run \
	-i \
	--rm \
	--link $pg_cid:pg \
	--link $server_cid:conjur \
	-v $PWD:/src/conjur \
	-v $PWD/run/authn-local:/run/authn-local \
	-e DATABASE_URL=postgres://postgres@pg/postgres \
	-e RAILS_ENV=test \
	-e CONJUR_APPLIANCE_URL=http://conjur \
	-e CONJUR_ADMIN_PASSWORD=admin \
	--entrypoint bash \
	conjur-test:$TAG
#!/bin/bash -ex

for i in $(seq 10); do
	curl -o /dev/null -fs -X OPTIONS http://conjur > /dev/null && break
	echo -n "."
	sleep 2
done

cd /src/conjur

rm -rf coverage
rm -rf spec/reports/*
rm -rf cucumber/api/features/reports/*
rm -rf cucumber/policy/features/reports/*

bundle exec rake jenkins
TEST
