#!/usr/bin/env ruby

require 'conjur-api'
require 'securerandom'

username = "admin"
password = "secret"

Conjur.configuration.appliance_url = "https://conjur_4/api"
Conjur.configuration.account = "cucumber"
Conjur.configuration.cert_file = "./tmp/conjur.pem"
Conjur.configuration.version = 4
Conjur.configuration.apply_cert_config!

puts "Configured with Conjur version: #{Conjur.configuration.version}"
puts

api_key = Conjur::API.login username, password
api = Conjur::API.new_from_key username, api_key

db_password = SecureRandom.hex(12)
puts "Populating variable 'db-password' = #{db_password.inspect}"
api.resource("cucumber:variable:db-password").add_value db_password
puts "Value added"
puts

puts "Creating host factory token for 'myapp'"
expiration = Time.now + 1.day
hf_token = api.resource("cucumber:host_factory:myapp").create_token expiration
puts "Created: #{hf_token.token}"
puts

puts "Creating new host 'host-01' with host factory"
host = Conjur::API.host_factory_create_host(hf_token, "host-01")
puts "Created: #{host}"
puts

puts "Logging in as #{host.id}"
host_api = Conjur::API.new_from_key "host/host-01", host.api_key
puts "Logged in"
puts


puts "Fetching db-password as #{host.id}"
value = host_api.resource("cucumber:variable:db-password").value
puts value
puts

puts "Done!"
