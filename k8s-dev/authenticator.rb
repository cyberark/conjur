#!/usr/bin/env ruby

require 'conjur-api'
require 'conjur-cli'
require 'restclient'

once = true if ARGV.shift == "--once"

Conjur::Config.load
Conjur::Config.apply
Conjur.log = $stderr

filename = "/run/conjur/access-token"
login_url = "#{Conjur.configuration.appliance_url}/authn/#{Conjur.configuration.account}/login-kubernetes"

$stderr.puts "Logging in with #{login_url}"

while true
  begin
    api_key = RestClient::Resource.new(login_url).get
    break
  rescue
    $stderr.puts $!
    sleep 5
  end
end

$stderr.puts "Logged in"

username = "host/kubernetes/#{ENV['K8S_NAMESPACE']}/deployment/myapp"
authenticate = lambda {
  Conjur::API.authenticate username, api_key
}

if once
  Conjur::Authenticator.new(authenticate, filename).refresh
else
  Conjur::Authenticator.run authenticate: authenticate, filename: filename
end
