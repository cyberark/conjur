require 'rest-client'
require 'aruba'
require 'aruba/cucumber'
require 'conjur-api'

require ::File.expand_path('../../../../../config/environment', __FILE__)

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://possum'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
