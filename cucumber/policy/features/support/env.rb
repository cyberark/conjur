# frozen_string_literal: true

require 'aruba'
require 'aruba/cucumber'

def appliance_url
  ENV['CONJUR_APPLIANCE_URL'] || 'http://conjur'
end

def account
  ENV['CONJUR_ACCOUNT'] || 'cucumber'
end

# This is needed to run the cucumber --profile policy successfully
# otherwise it fails due to the way root_loader sets its admin password
ENV.delete('CONJUR_ADMIN_PASSWORD')

# so that we can require relative to the project root
$LOAD_PATH.unshift(File.expand_path('../../../..', __dir__))
require 'config/environment'
