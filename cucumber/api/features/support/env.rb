ENV['CONJUR_ACCOUNT'] = 'cucumber'
ENV['CONJUR_APPLIANCE_URL'] ||= 'http://conjur'

require ::File.expand_path('../../../../../config/environment', __FILE__)

require 'json_spec/cucumber'

Slosilo["authn:cucumber"] ||= Slosilo::Key.new

require 'simplecov'
