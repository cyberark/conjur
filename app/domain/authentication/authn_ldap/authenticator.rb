# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'net/ldap'

module Authentication
  module AuthnLdap

    class Authenticator

      def initialize(env:,
                     ldap_server_factory: ::Authentication::AuthnLdap::Server)
        @env = env
        @filter = env['LDAP_FILTER'] || '(&(objectClass=posixAccount)(uid=%s))'
        @ldap_server = ldap_server_factory.new(
          uri:     env['LDAP_URI'],
          base:    env['LDAP_BASE'],
          bind_dn: env['LDAP_BINDDN'],
          bind_pw: env['LDAP_BINDPW']
        )
      end

      def valid?(input)
        login, password = input.username, input.password
        # Prevent LDAP injection attack
        safe_login = Net::LDAP::Filter.escape(login)
        return false if blacklisted_ldap_user?(safe_login)

        filter = @filter % safe_login
        bind_results = @ldap_server.bind_as(filter: filter, password: password)
        bind_results ? true : false
      end

      private

      # admin should only be able to login through plain Conjur authn
      def blacklisted_ldap_user?(login)
        login == 'admin'
      end
    end

  end
end
