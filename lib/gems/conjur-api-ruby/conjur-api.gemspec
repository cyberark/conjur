# -*- encoding: utf-8 -*-
require File.expand_path('../lib/conjur-api/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rafal Rzepecki","Kevin Gilpin"]
  gem.email         = ["rafal@conjur.net","kgilpin@conjur.net"]
  gem.description   = %q{Conjur API}
  gem.summary       = %q{Conjur API}
  gem.homepage      = "https://github.com/cyberark/conjur-api-ruby/"
  gem.license       = "Apache-2.0"

  gem.files         = `git ls-files`.split($\) + Dir['build_number']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "conjur-api"
  gem.require_paths = ["lib"]
  gem.version       = Conjur::API::VERSION

  gem.required_ruby_version = '>= 1.9'

  gem.add_dependency 'rest-client'
  gem.add_dependency 'activesupport'

  gem.add_development_dependency 'rake', '~> 10.0'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'rspec-expectations', '~> 3.4'
  gem.add_development_dependency 'json_spec'
  gem.add_development_dependency 'cucumber', '~> 2.99'
  gem.add_development_dependency 'ci_reporter_rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'io-grab'
  gem.add_development_dependency 'rdoc'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'fakefs'
  gem.add_development_dependency 'pry-byebug'
end
