#!/usr/bin/env ruby

require 'conjur-api'

api = Conjur::API.new_from_token_file "/run/conjur/access-token"
variable_id = "#{Conjur.configuration.account}:variable:prod/mydb/password"

while true
  begin
    password = api.resource(variable_id).value
    puts "Database password : #{password}"
    $stdout.flush
  rescue RestClient::NotFound
    $stderr.puts "Value for #{variable_id.inspect} was not found. Is the variable created, and is the secret value added?"
  end  
  sleep 5
end
