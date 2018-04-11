#!/usr/bin/env ruby

require 'conjur-api'
require 'securerandom'

username = "admin"

arguments = ARGV.dup

api_key = arguments.shift or raise "Usage: ./demo_v5 <admin-api-key>"

Conjur.configuration.appliance_url = "http://conjur_5"
Conjur.configuration.account = "cucumber"
# This is the default
# Conjur.configuration.version = 5

puts "Configured with Conjur version: #{Conjur.configuration.version}"
puts

api = Conjur::API.new_from_key username, api_key

policy = File.read("features_v4/support/policy.yml")

puts "Loading policy 'root'"
policy_result = api.load_policy "root", policy
puts "Loaded: #{policy_result}"
puts

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
