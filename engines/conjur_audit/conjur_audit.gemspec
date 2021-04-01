# frozen_string_literal: true

$LOAD_PATH.push(File.expand_path("../lib", __FILE__))

# Maintain your gem's version:
require "conjur_audit/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "conjur_audit"
  s.version     = ConjurAudit::VERSION
  s.authors     = ["Rafał Rzepecki"]
  s.email       = ["rafal.rzepecki@cyberark.com"]
  s.summary     = "Rails engine to query Conjur audit database"
  s.license     = "AGPL-3"

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency("pg")
  s.add_dependency("rails", "~> 4.2.8")
  s.add_dependency("sequel-rails", "~> 0.9.15")

  s.add_development_dependency("rspec-rails", "~> 3.5.2")
end
