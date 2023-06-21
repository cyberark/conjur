# frozen_string_literal: true

# so that we can require relative to the project root
$LOAD_PATH.unshift(Dir.pwd)
require 'config/environment'
require 'cucumber/timecop'

ENV['RAILS_ENV'] ||= 'test'
ENV['CONJUR_LOG_LEVEL'] ||= 'debug'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://conjur'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
