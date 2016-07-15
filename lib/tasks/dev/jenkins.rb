require 'ci/reporter/rake/rspec'

namespace :jenkins do
  require 'cucumber'
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:cucumber) do |t|
    t.cucumber_opts = "--tags ~@wip --format pretty --format junit --out features/reports"
  end

  task :rspec => ['ci:setup:rspec', :spec]
end

task :jenkins => ['db:migrate', 'jenkins:rspec', 'jenkins:cucumber']
