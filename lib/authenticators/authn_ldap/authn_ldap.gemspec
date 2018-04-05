$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "authn_ldap/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "authn_ldap"
  s.version     = AuthnLdap::VERSION
  s.authors     = [""]
  s.email       = [""]
  # s.homepage    = "blah"
  s.summary     = "blah: Summary of AuthnLdap."
  s.description = "blah: Description of AuthnLdap."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  # s.add_dependency "rails", "~> 4.2.8"
  s.add_dependency 'rails-api'
  s.add_dependency 'net-ldap'
  s.add_dependency 'activesupport'
  s.add_dependency 'authn_core'
  s.add_dependency 'conjur-api', '~> 5.0.0.beta'

  # s.add_development_dependency "sqlite3"
end
