# frozen_string_literal: true

# so that we can require relative to the project root
$LOAD_PATH.unshift(Dir.pwd)
require 'config/environment'

require 'json_spec/cucumber'
require_relative 'utils'

ENV['CONJUR_ACCOUNT'] = 'cucumber'
ENV['RAILS_ENV'] ||= 'test'

# This line is here to support running these tests outside a container,
# per Rafal's request.  It could be deleted were it not for that.
ENV['CONJUR_APPLIANCE_URL'] ||= Utils.start_local_server

Slosilo["authn:cucumber"] ||= Slosilo::Key.new
