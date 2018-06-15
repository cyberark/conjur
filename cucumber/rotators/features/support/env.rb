# TODO: find better way to share common World
# Bring in the policy's World
#
require_relative './world.rb'
require_relative '../../../policy/features/support/world.rb'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://possum'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'

World(PossumWorld)
World(RotatorWorld)
