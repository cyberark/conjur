# frozen_string_literal: true

# Bring in the policy's World
#
require_relative './world.rb'
# require_relative '../../../policy/features/support/world.rb'

ENV['RAILS_ENV'] ||= 'test'
require ::File.expand_path('../../../../../config/environment', __FILE__)

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://possum'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'

World(PossumWorld)
World(RotatorWorld)
