# frozen_string_literal: true

$LOAD_PATH.unshift(Dir.pwd)
require 'config/environment'

require 'rest-client'
require 'aruba'
require 'aruba/cucumber'
require 'conjur-api'
require 'json_spec/cucumber'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://conjur'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
