ENV['CONJUR_ACCOUNT'] = 'cucumber'
ENV['CONJUR_APPLIANCE_URL'] ||= 'http://localhost:3000'

require ::File.expand_path('../../../../../config/environment', __FILE__)

require 'json_spec/cucumber'

Slosilo["authn:cucumber"] ||= Slosilo::Key.new

require 'simplecov'
