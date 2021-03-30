#!/usr/bin/env ruby

# This script generates an html coverage report from simplecov json output.
# Normally simplecov generates the html report at the end of a run, however
# the conjur tests produce multiple simplecov reports, each with json data
# and an html report. The json files are easy enough to merge, the html reports
# are much harder. So instead we merge the json files then use this script
# to generate a new html report. See ci/submit-coverage for the merge.

require 'json'
require 'simplecov'

# Override at_exit callback as we don't want this program to hang forever
# (.simplecov adds infinite sleep to keep containers alive after writing the
# coverage report)
# We also don't actually want a coverage report for this script ;-)
SimpleCov.at_exit do
end

if ARGV.size != 2
  puts "Usage: generate_report.rb <project root dir> <report json file>"
  exit!
end

# Simplecov filters exclude all files outside the current project root.
# The project root defaults to the working directory, so we have to move
# the root up a couple of levels so all the source files can be included.
# Use the first argument so the user can specify the approprite dir
SimpleCov.root(ARGV[0])

# Set the merge timeout so that older reports in the same file don't get
# dropped when merging.
SimpleCov.merge_timeout(1800)

# Read the result file, path passed in as second arg.
jsonraw = File.open(ARGV[1]).read

# Parse JSON to create ruby object
jsonobj = JSON.parse(jsonraw)

# Create result object for each subresult
resultobjs = jsonobj.keys.map do |key|
  SimpleCov::Result.from_hash(key => jsonobj[key])
end

# Merge the sub-results.
# This is actually the second merge (ci/submit-coverage uses jq to merge
# multiple result files together, this merges separate sub reports within the
# one json structure.)
mergedresult = SimpleCov::ResultMerger.merge_results(*resultobjs)

# Format the result using the html formatter
formatter = SimpleCov::Formatter::HTMLFormatter.new
formatter.format(mergedresult)
