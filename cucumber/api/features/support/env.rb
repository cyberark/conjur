# frozen_string_literal: true

require_relative 'utils'
require 'json_spec/cucumber'
require ::File.expand_path('../../../../../config/environment', __FILE__)

ENV['CONJUR_ACCOUNT'] = 'cucumber'
ENV['RAILS_ENV'] ||= 'test'
ENV['CONJUR_APPLIANCE_URL'] ||= Utils.start_local_server

Slosilo["authn:cucumber"] ||= Slosilo::Key.new
