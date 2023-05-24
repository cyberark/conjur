# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conjur/rack/version'

Gem::Specification.new do |spec|
  spec.name          = "conjur-rack"
  spec.version       = Conjur::Rack::VERSION
  spec.authors       = ["Kevin Gilpin"]
  spec.email         = ["kgilpin@conjur.net"]
  spec.description   = %q{Rack authenticator and basic User struct}
  spec.summary       = %q{Rack authenticator and basic User struct}
  spec.homepage      = "http://github.com/conjurinc/conjur-rack"
  spec.license       = "Private"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "slosilo", "~> 3.0"
  spec.add_dependency "conjur-api", "< 6"
  spec.add_dependency "rack", "~> 2"
  
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "activesupport", "< 7"
  spec.add_development_dependency 'ci_reporter_rspec'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rspec-its'

end
