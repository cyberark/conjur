#!/bin/bash -ex

VERSION=latest

usage() {
    cat <<EOF
usage: $(basename $0) [-h] [-v <version>]
    -h              Show help
    -v <version>    Version to publish [default: latest]
EOF
}

while getopts "hv:" opt; do
    case "$opt" in
        h) usage
           exit 0
           ;;

        v) VERSION=$OPTARG
           ;;

        \?) usage >&2
            exit 1
            ;;
    esac
done

./build.sh

docker tag -f possum registry.tld/conjurinc/possum:${VERSION}

docker push registry.tld/conjurinc/possum:${VERSION}
