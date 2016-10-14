#!/bin/bash -ex

debify clean

./build.sh

debify package \
  possum \
  -- \
  --depends "conjur-appliance (>= 5.0)"

function finish {
	docker rm -f $pg_cid
	docker rm -f $server_cid
}
trap finish EXIT

export POSSUM_DATA_KEY="$(docker run --rm possum data-key generate)"

pg_cid=$(docker run -d postgres:9.3)

mkdir -p spec/reports
mkdir -p cucumber/api/features/reports
mkdir -p cucumber/policy/features/reports

server_cid=$(docker run -d \
	--link $pg_cid:pg \
	-e DATABASE_URL=postgres://postgres@pg/postgres \
	-e RAILS_ENV=test \
	possum server)

cat << "TEST" | docker run \
	-i \
	--rm \
	--link $pg_cid:pg \
	--link $server_cid:possum \
	-v $PWD:/src/possum \
	-e DATABASE_URL=postgres://postgres@pg/postgres \
	-e RAILS_ENV=test \
	-e CONJUR_APPLIANCE_URL=http://possum \
	-e POSSUM_ADMIN_PASSWORD=admin \
	--entrypoint bash \
	possum-test
#!/bin/bash -ex

for i in $(seq 10); do
	curl -o /dev/null -fs -X OPTIONS http://possum > /dev/null && break
	echo -n "."
	sleep 2
done

cd /src/possum

rm -rf coverage
rm -rf spec/reports/*
rm -rf cucumber/api/features/reports/*
rm -rf cucumber/policy/features/reports/*

bundle exec rake jenkins || true
TEST
