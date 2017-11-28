require 'aruba'
require 'aruba/cucumber'
require 'conjur-api'
require 'open-uri'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://possum'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'

$policy_dir = if File.exists?("/run")
  "/run"
else
  File.expand_path('../../../../../run', __FILE__)
end

system *[ 'rake', 'policy:load[cucumber,./run/empty.yml]' ] or raise "Failed to load policy: #{$?.exitstatus}"
