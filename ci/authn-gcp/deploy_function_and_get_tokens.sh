#!/bin/bash -ex

# Script that runs the deploy function and get tokens to files scripts

main() {
  echo "Deploy function and get tokens"
  summon ./run_gcloud.sh deploy_function.sh

  if [ $? -ne 0 ]; then
      echo '-- Error deploying Google function'
      exit 1
  fi
  echo "-- Function deployed..."

  echo '-- Obtain tokens from Google function and write to files...'
  ./get_func_tokens_to_files.sh
  if [ $? -ne 0 ]; then
      echo '-- Error obtaining tokens from Google function'
      exit 1
  fi
  echo "-> Deploy function and get tokens done"
}

main || exit 1
