# frozen_string_literal: true

require 'aruba'
require 'aruba/cucumber'
require 'conjur-api'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://conjur'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
