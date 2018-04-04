# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'bundler/version'
 
Gem::Specification.new do |s|
  s.name        = "authn-ldap-v5"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jonah Goldstein"]
  s.email       = ["jonah.goldstein@cyberark.com"]
  s.homepage    = "http://www.example.com"
  s.summary     = "Login to Conjur using LDAP"
  s.description = "Login to Conjur using LDAP"
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_dependency('sinatra', '~>2.0')
  s.add_dependency('conjur-api', '>=5.0.0')
  s.add_dependency('net-ldap', '~>0.16.1')
  s.add_dependency('conjur-rack-heartbeat', '~>2.0')
  s.add_dependency('conjur-appliance-logging', '~>0.3.1')

  s.add_development_dependency('puma')
  s.add_development_dependency('pry')
  s.add_development_dependency('cucumber')
  s.add_development_dependency('rspec')
  s.add_development_dependency('rspec-mocks')
  s.add_development_dependency('rspec-expectations')
  s.add_development_dependency('ladle')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('ci_reporter_rspec')
  s.add_development_dependency('rest-client')
  s.add_development_dependency('rerun')
 
  # s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md ROADMAP.md CHANGELOG.md)

  s.files = Dir[
    "{bin,ci,spec,features,lib}/**/*",
    "Dockerfile.test",
    "docker-compose.yml",
    "README.md",
    "VERSION_APPLIANCE"
  ]
  # test_files is not longer a thing after ruby 2.2...
  # s.test_files = Dir["{bin,ci,spec,features}/**/*", "Dockerfile.test", "docker-compose.yml"]
end

__END__

40_authn-local.conf  Dockerfile.test      JONAHS_DEV_NOTES.md  VERSION_APPLIANCE    bin/                 docker-compose.yml   spec/
CHANGELOG.md         Gemfile              README.md            app.rb               ci/                  features/
Dockerfile           Gemfile.lock         VERSION              authn_ldap.gemspec   config.ru            lib/
