require 'aruba'
require 'aruba/cucumber'

$possum_url = ( ENV['CONJUR_APPLIANCE_URL'] || 'http://possum' )
$possum_account = ( ENV['CONJUR_ACCOUNT'] || 'cucumber' )
$policy_dir = if File.exists?("/run")
  "/run"
else
  File.expand_path('../../../../../run', __FILE__)
end

Slosilo["authn:cucumber"] ||= Slosilo::Key.new

require 'simplecov'
SimpleCov.start
