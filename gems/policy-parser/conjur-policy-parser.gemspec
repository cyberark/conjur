# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conjur-policy-parser-version'

Gem::Specification.new do |spec|
  spec.name           = "conjur-policy-parser"
  spec.version        = Conjur::PolicyParser::VERSION
  spec.authors        = ["Cyberark R&D"]
  spec.summary        = 'Parses Conjur YAML policy.'
  spec.description    = 'This gem provides two way translation from Conjur Policy YAML to Ruby objects and Ruby objects to Conjur Policy YAML.'
  spec.files          = Dir.glob("{bin,lib}/**/*") + %w(README.md)
  spec.require_paths  = ["lib"]

  spec.add_dependency "activesupport", ">= 4.2"
  spec.add_dependency "safe_yaml"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "ci_reporter_rspec"
  spec.add_development_dependency "deepsort"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-expectations"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-cobertura"
end
