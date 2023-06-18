# -*- encoding: utf-8 -*-
begin
  require File.expand_path('../lib/slosilo/version', __FILE__)
rescue LoadError
  # so that bundle can be run without the app code
  module Slosilo
    VERSION = '0.0.0'
  end
end

Gem::Specification.new do |gem|
  gem.authors       = ["Rafa\305\202 Rzepecki"]
  gem.email         = ["divided.mind@gmail.com"]
  gem.description   = %q{This gem provides an easy way of storing and retrieving encryption keys in the database.}
  gem.summary       = %q{Store SSL keys in a database}
  gem.homepage      = ""
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "slosilo"
  gem.require_paths = ["lib"]
  gem.version       = Slosilo::VERSION
  gem.required_ruby_version = '>= 3.0.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'ci_reporter_rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'simplecov-cobertura'
  gem.add_development_dependency 'io-grab', '~> 0.0.1'
  gem.add_development_dependency 'sequel' # for sequel tests
  gem.add_development_dependency 'sqlite3' # for sequel tests
  gem.add_development_dependency 'activesupport' # for convenience in specs
end
