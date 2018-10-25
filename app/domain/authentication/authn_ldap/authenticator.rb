# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'net/ldap'

module Authentication
  module AuthnLdap

    class Authenticator
      def initialize(env:,
                     ldap_server_factory: ::Authentication::AuthnLdap::Server,
                     role_cls: ::Authentication::MemoizedRole,
                     credentials_cls: ::Credentials)
        @env = env
        @ldap_server_factory = ldap_server_factory
        @role_cls = role_cls
        @credentials_cls = credentials_cls
      end

      # Authenticate the role using LDAP credentials
      def valid?(input)
        login, password = input.username, input.password

        # Prevent anonymous LDAP authentication with username only
        return false if password.blank?

        # Prevent LDAP injection attack
        safe_login = Net::LDAP::Filter.escape(login)
        return false if blacklisted_ldap_user?(safe_login)

        # Authenticate against LDAP
        filter = filter_template % safe_login
        bind_results = ldap_server.bind_as(filter: filter, password: password)
        return bind_results.present?
      end

      private

      def filter_template
        @filter_template ||= 
          @env['LDAP_FILTER'] || '(&(objectClass=posixAccount)(uid=%s))'
      end

      def ldap_server
        @ldap_server ||= @ldap_server_factory.new(
          uri:     @env['LDAP_URI'],
          base:    @env['LDAP_BASE'],
          bind_dn: @env['LDAP_BINDDN'],
          bind_pw: @env['LDAP_BINDPW']
        )
      end

      def conjur_authenticator
        Authentication::Authn::Authenticator.new
      end

      # admin should only be able to login through plain Conjur authn
      def blacklisted_ldap_user?(login)
        login == 'admin'
      end
    end

  end
end
