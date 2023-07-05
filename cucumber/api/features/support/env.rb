# frozen_string_literal: true

ENV['CONJUR_ACCOUNT'] = 'cucumber'
ENV['RAILS_ENV'] ||= 'test'
ENV['CONJUR_LOG_LEVEL'] ||= 'debug'

parallel_cuke_vars = {}
parallel_cuke_vars['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
parallel_cuke_vars['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
parallel_cuke_vars['CONJUR_AUTHN_API_KEY'] = ENV["CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"]
parallel_cuke_vars['AUTHN_LOCAL_SOCKET'] = ENV["AUTHN_LOCAL_SOCKET#{ENV['TEST_ENV_NUMBER']}"]

parallel_cuke_vars.each do |key, value|
  if ENV[key].nil? || ENV[key].empty?
    ENV[key] = value
  end
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

Slosilo["authn:cucumber:user:current"] ||= Slosilo::Key.new
Slosilo["authn:cucumber:host:current"] ||= Slosilo::Key.new
Slosilo["authn:cucumber:user:previous"] ||= Slosilo::Key.new
Slosilo["authn:cucumber:host:previous"] ||= Slosilo::Key.new

JsonSpec.excluded_keys = %w[created_at updated_at]
