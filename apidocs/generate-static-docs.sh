#!/bin/bash

outfile="${1:-output.html}"

./node_modules/.bin/aglio -i src/api.md -o "$outfile"
