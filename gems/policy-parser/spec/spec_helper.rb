# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/features/'
  enable_coverage :branch
  primary_coverage :branch
end

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'conjur-policy-parser'
require 'logger'

if ENV['DEBUG']
  Conjur::PolicyParser::YAML::Handler.logger.level = Logger::DEBUG
end

require 'sorted_yaml'
RSpec.configure do |c|
  c.include(SortedYAML)
  c.order = "random"
  c.filter_run_when_matching(:focus)
end
