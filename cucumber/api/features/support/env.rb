# frozen_string_literal: true

ENV['CONJUR_ACCOUNT'] = 'cucumber'
ENV['RAILS_ENV'] ||= 'test'
ENV['CONJUR_LOG_LEVEL'] ||= 'debug'

if ENV['TEST_ENV_NUMBER'] < "2"
    print "PROCESS IS: #{ENV['TEST_ENV_NUMBER']}"
    print ""
    ENV['CONJUR_APPLIANCE_URL'] = "http://conjur"
    ENV['DATABASE_URL'] = "postgres://postgres@pg/postgres"
    print "DATABASE_URL: #{ENV['DATABASE_URL']}"
else
    print "PROCESS IS: #{ENV['TEST_ENV_NUMBER']}"
    print ""
    ENV['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
    ENV['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
    print "DATABASE_URL: #{ENV['DATABASE_URL']}"
end

# so that we can require relative to the project root
$LOAD_PATH.unshift(File.expand_path('../../../..', __dir__))
require 'config/environment'

require 'json_spec/cucumber'
require_relative 'utils'
require 'tmpdir'
require 'securerandom'

# This line is here to support running these tests outside a container,
# per Rafal's request.  It could be deleted were it not for that.
ENV['CONJUR_APPLIANCE_URL'] ||= Utils.start_local_server

Slosilo["authn:cucumber"] ||= Slosilo::Key.new

JsonSpec.excluded_keys = %w[created_at updated_at]
