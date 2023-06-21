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
  gem.name          = "slosilo"
  gem.version       = Slosilo::VERSION
  gem.authors       = ["Cyberark R&D"]
  gem.summary       = %q{Store SSL keys in a database}
  gem.description   = %q{This gem provides an easy way of storing and retrieving encryption keys in the database.}
  gem.homepage      = ""

  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.require_paths = ["lib"]
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
