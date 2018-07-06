# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require ::File.expand_path('../../../../../config/environment', __FILE__)

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://possum'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
