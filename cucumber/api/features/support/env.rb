# frozen_string_literal: true

require_relative 'utils'

ENV['CONJUR_ACCOUNT'] = 'cucumber'
ENV['RAILS_ENV'] ||= 'test'

require ::File.expand_path('../../../../../config/environment', __FILE__)

ENV['CONJUR_APPLIANCE_URL'] ||= Utils.start_local_server

require 'json_spec/cucumber'

Slosilo["authn:cucumber"] ||= Slosilo::Key.new

require 'simplecov'
