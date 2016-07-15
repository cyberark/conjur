#!/bin/bash -ex

./build.sh

function finish {
	docker rm -f $pg_cid
	docker rm -f $server_cid
}
trap finish EXIT

export POSSUM_DATA_KEY="$(docker run --rm possum data-key generate)"

pg_cid=$(docker run -d postgres:9.3)

for i in $(seq 10); do
	docker exec $pg_cid psql -q -U postgres -c 'select 1' > /dev/null && break
	echo -n "."
	sleep 2
done

server_cid=$(docker run --link $pg_cid:pg -e CONJUR_APPLIANCE_URL=http://localhost -e DATABASE_URL=postgres://postgres@pg/postgres -e CONJUR_ACCOUNT=cucumber -d possum server)

cat << "TEST" | docker exec -i $server_cid bash
#!/bin/bash -ex

export CONJUR_APPLIANCE_URL=http://localhost

for i in $(seq 10); do
	curl -o /dev/null -fsk http://localhost/info > /dev/null && break
	echo -n "."
	sleep 2
done

bundle exec rake jenkins || true
TEST
