# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

ENV['CONJUR_ACCOUNT'] = 'rspec'
  
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.order = "random"
  config.filter_run_excluding performance: true
  config.infer_spec_type_from_file_location!
end

Slosilo["authn:rspec"] ||= Slosilo::Key.new

require 'simplecov'
