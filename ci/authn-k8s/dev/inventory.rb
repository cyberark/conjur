#!/usr/bin/env ruby

require 'sinatra'
require 'conjur-api'
require 'cgi'
require 'json'

enable :logging

helpers do
  def username
    raise "Expecting CONJUR_AUTHN_API_KEY to be blank" if ENV['CONJUR_AUTHN_API_KEY']
    ENV['CONJUR_AUTHN_LOGIN'] or raise "No CONJUR_AUTHN_LOGIN"
  end
  
  def conjur_api
    # Ideally this would be done only once.
    # But for testing, it means that if the login fails, the pod is stuck in a bad state
    # and the tests can't be performed.
    Conjur.configuration.apply_cert_config!
    
    token = JSON.parse(File.read("/run/conjur/access-token"))
    Conjur::API.new_from_token(token)
  end
end

get '/' do
  begin
    password = conjur_api.variable("inventory-db/password").value
    "inventory-db password: #{password}"
  rescue
    $stderr.puts $!
    $stderr.puts $!.backtrace.join("\n")
    halt 500, "Error: #{$!}"
  end
end
