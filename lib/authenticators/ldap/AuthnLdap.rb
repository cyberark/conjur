require 'active_support'
require 'active_support/core_ext'
require 'net/ldap'

module AuthnLdap

  class Authenticator

    def initialize(ldap_server:, ldap_filter: nil)
      @ldap_server = ldap_server
      @filter = ldap_filter || '(&(objectClass=posixAccount)(uid=%s))'
    end

    def valid?(login, password)
      return false if login.blank? || password.blank?
      valid_ldap_credentials?(login, password)
    end

    protected

    def valid_ldap_credentials?(login, password)
      # Prevent LDAP injection attack
      safe_login = Net::LDAP::Filter.escape(login)
      return false if blacklisted_ldap_user?(safe_login)

      filter = @filter % safe_login
      bind_results = @ldap_server.bind_as(filter: filter, password: password)
      bind_results ? true : false
    end

    # admin should only be able to login through plain Conjur authn
    def blacklisted_ldap_user?(login)
      login == 'admin'
    end
  end

  class Server

  	def self.new(uri:, base:, bind_dn:, bind_pw:, log: nil)
  		Net::LDAP.new(options(log)).tap do |ldap|
  			if uri
  				uri_obj = URI.parse(uri)
  				ldap.host = uri_obj.host
  				ldap.port = uri_obj.port
  				ldap.encryption(:simple_tls) if uri_obj.scheme == 'ldaps'
  			end

  			ldap.auth(bind_dn, bind_pw) if bind_dn
  			ldap.base = base
  		end
  	end

  	private

  	def self.options(log)
  		log ? {instrumentation_service: log} : {}
  	end

  end
end
