#!/bin/bash -ex

debify clean

./build.sh
./package.sh
./test.sh
