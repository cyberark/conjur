#!/bin/bash -ex

# Script that retrieving instance metadata from Google cloud metadata server.


main() {
  get_gce_instance_project_id
  get_gce_instance_zone
}

get_gce_instance_project_id() {
  echo 'get_gce_instance_project_id'
  GCP_PROJECT=$(curl -s -H "Metadata-Flavor: Google" \
                  "http://metadata.google.internal/computeMetadata/v1/project/project-id") || exit 1
  echo '-> get_gce_instance_project_id done'
}

get_gce_instance_zone() {
  echo 'get_gce_instance_zone'
  GCP_ZONE=$(curl -s -H "http://metadata.google.internal/computeMetadata/v1/instance/") || exit 1
  echo '-> get_gce_instance_zone done'
}

main || exit 1
