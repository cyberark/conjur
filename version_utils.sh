#!/bin/bash

# Functions to generate version numbers for this project

version_tag() {
  echo "$(< VERSION)-$(git rev-parse --short HEAD)"
}
