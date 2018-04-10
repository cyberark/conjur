require 'active_support'
require 'active_support/core_ext'
require 'net/ldap'
require 'conjur/api'

module AuthnLdap

  class Authenticator

    def initialize(ldap_server:, ldap_filter: nil, conjur_api: Conjur::API)
      @ldap_server = ldap_server
      @filter = ldap_filter || '(&(objectClass=posixAccount)(uid=%s))'
      @conjur_api = conjur_api
    end

    # Takes an LDAP username / password and returns an access token
    #
    # @param [String] LDAP username
    # @param [String] LDAP password
    # @param [String] account Conjur account
    # @return [String] A JSON formatted authentication token.
    def auth(username, password, account)
      puts "**************************************************"
      puts "auth"
      return false if username.blank? || password.blank?

      # Login via LDAP
      puts "**************************************************"
      puts "valid_ldap_credentials"

      if valid_ldap_credentials?(username, password)
        @conjur_api.authenticate_local(username, account: account)
      else
        false
      end
    rescue => e
      puts "ERROR"
      puts e
      false
    end

    protected

    def valid_ldap_credentials?(username, password)
      # Prevent LDAP injection attack
      safe_username = Net::LDAP::Filter.escape(username)

      return false if blacklisted_ldap_user?(safe_username)

      puts "Before binding"

      bind_results = @ldap_server.bind_as(
        filter: @filter % safe_username,
        password: password
      )
      puts "bind results: #{bind_results}"
      bind_results ? true : false
    end

    # admin should only be able to login through plain Conjur authn
    def blacklisted_ldap_user?(username)
      username == 'admin'
    end
  end
end
