#!/bin/bash -ex

for kind in api policy; do
	rm -rf /mnt/doc/$kind
	cd /opt/possum/cucumber/$kind
	yardoc features/*.feature
	cp -r doc /mnt/doc/$kind
done
