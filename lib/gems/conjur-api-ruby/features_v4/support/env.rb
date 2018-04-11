require 'simplecov'

SimpleCov.start

require 'json_spec/cucumber'
require 'conjur/api'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'https://conjur_4/api'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
Conjur.configuration.cert_file = "./tmp/conjur.pem"
Conjur.configuration.authn_local_socket = "/run/authn-local-4/.socket"
Conjur.configuration.version = 4

Conjur.configuration.apply_cert_config!

$username = ENV['CONJUR_AUTHN_LOGIN'] || 'admin'
$password = ENV['CONJUR_AUTHN_API_KEY'] || 'secret'

$api_key = Conjur::API.login $username, $password
$conjur = Conjur::API.new_from_key $username, $api_key

$host_factory = $conjur.resource('cucumber:host_factory:myapp')
$token = $host_factory.create_token(Time.now + 1.hour)
