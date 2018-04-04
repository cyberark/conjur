require 'sinatra'
require 'json'
require 'net/ldap'
require 'uri'
require 'authenticator'
require 'conjur-rack-heartbeat'
require 'conjur-appliance-logging'
require 'ldap_log'
require 'ldap_server'

class WS < Sinatra::Base
  extend Conjur::Appliance::Logging::Sinatra
  
  use Rack::Heartbeat
 
  post '/users/:login/authenticate' do
    login    = params[:login]
    password = request.body.read
    token    = authenticator.auth(login, password)

    if token
      content_type "application/json"
      token.to_json
    else
      status 401
    end
  end
  
	private

	def authenticator
		@authenticator ||= Authenticator.new(
			ldap_server: LdapServer.new(
				uri:     ENV['LDAP_URI'],
				base:    ENV['LDAP_BASE'],
				bind_dn: ENV['LDAP_BINDDN'],
				bind_pw: ENV['LDAP_BINDPW'],
				log:     ldap_log
			),
			ldap_filter: ENV['LDAP_FILTER']
		)
	end

	def ldap_log
		x = ENV['LOG_LEVEL'] == 'debug' ? LdapLog.new : nil
    puts 'x', x
    return x
	end

end
