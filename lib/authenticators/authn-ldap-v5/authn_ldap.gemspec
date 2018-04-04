# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'bundler/version'
 
Gem::Specification.new do |s|
  s.name        = "authn-ldap"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jonah Goldstein"]
  s.email       = ["jonah.goldstein@cyberark.com"]
  s.homepage    = "None"
  s.summary     = "Login to Conjur using LDAP"
  s.description = "Login to Conjur using LDAP"
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_dependency('sinatra', '2.0.1')
  s.add_dependency('conjur-api', '5.1.0')
  s.add_dependency('net-ldap', '0.16.1')
  s.add_dependency('conjur-rack-heartbeat', '2.0.0')

  s.add_development_dependency('puma')
 
  # s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md ROADMAP.md CHANGELOG.md)

  # s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  # s.test_files = Dir["test/**/*"]
  s.executables  = ['bundle']
  s.require_path = 'lib'
end

__END__

40_authn-local.conf  Dockerfile.test      JONAHS_DEV_NOTES.md  VERSION_APPLIANCE    bin/                 docker-compose.yml   spec/
CHANGELOG.md         Gemfile              README.md            app.rb               ci/                  features/
Dockerfile           Gemfile.lock         VERSION              authn_ldap.gemspec   config.ru            lib/
