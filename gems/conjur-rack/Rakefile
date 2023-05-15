require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--format doc"
  unless ENV["CONJUR_ENV"] == "ci"
    t.rspec_opts << " --color"
  else 
    Rake::Task["ci:setup:rspec"].invoke
  end
end

task :default => :spec
