#!/usr/bin/env rake
require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  $stderr.puts "RSpec Rake tasks not available in environment #{ENV['RACK_ENV']}"
end

task :jenkins do
  require 'ci/reporter/rake/rspec'
  Rake::Task["ci:setup:rspec"].invoke
  Rake::Task["spec"].invoke
end

task :default => :spec
