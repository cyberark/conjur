require 'ci/reporter/rake/rspec'

Rake::Task["ci:setup:spec_report_cleanup"].clear

namespace :ci do
  namespace :setup do
    task :spec_report_cleanup do
      dir = ENV["CI_REPORTS"] || "spec/reports"
      rm_rf dir unless File.symlink?(dir)
    end
  end
end

namespace :jenkins do
  require 'cucumber'
  require 'cucumber/rake/task'

  namespace :core do
    Cucumber::Rake::Task.new(:"cucumber-api") do |t|
      t.cucumber_opts = "--tags ~@wip -r cucumber/api/features/support -r cucumber/api/features/step_definitions " +
        "--format pretty --format junit --out cucumber/api/features/reports cucumber/api/features"
    end
    Cucumber::Rake::Task.new(:"cucumber-policy") do |t|
      t.cucumber_opts = '--tags ~@wip '\
                        '-r cucumber/policy/features/support '\
                        '-r cucumber/policy/features/step_definitions '\
                        '--format pretty '\
                        '--format junit '\
                        '--out cucumber/policy/features/reports '\
                        'cucumber/policy/features'
    end

    task rspec: ['ci:setup:rspec', :spec]
  end

  namespace :authn_ldap do
    Cucumber::Rake::Task.new(:"cucumber") do |t|
      t.cucumber_opts = '--tags ~@wip '\
                        '-r cucumber/authenticators/features/support '\
                        '-r cucumber/authenticators/features/step_definitions '\
                        '--format pretty '\
                        '--format junit '\
                        '--out cucumber/authenticators/features/reports '\
                        'cucumber/authenticators/features'
    end
  end

end

task jenkins: [
  'db:migrate',
  'jenkins:core:cucumber-api',
]
