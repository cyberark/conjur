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
  mkdir -p brakeman/reports
  chmod -R 0777 brakeman/reports
  # TODO Un-pin to stable when stable image runs without error.
  docker run -v "$(pwd):/tmp/" --rm -w /tmp/ codeclimate/codeclimate-brakeman brakeman:b804 -o brakeman/reports/brakeman-output.html
fi


if [[ $RUN_GEM_AUDIT = true ]]; then
  docker run -v "$(pwd):/tmp/" --rm -w /tmp/ codeclimate/codeclimate-bundler-audit bundle audit check --update
fi
