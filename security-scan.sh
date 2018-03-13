#!/bin/bash -ex

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -b|--brakeman)
    RUN_BRAKEMAN=true
    ;;
    -a|--gem-audit)
    RUN_GEM_AUDIT=true
    ;;
    *)
    ;;
esac
shift # past argument or value
done

if [[ $RUN_BRAKEMAN = true ]]; then
  docker run -v "$(pwd):/tmp/" -w /tmp/  codeclimate/codeclimate-brakeman brakeman
fi

if [[ $RUN_GEM_AUDIT = true ]]; then
  docker run -v "$(pwd):/tmp/" -w /tmp/ codeclimate/codeclimate-bundler-audit bundle audit check --update
fi
