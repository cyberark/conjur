# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'net/ldap'

module Authentication
  module AuthnLdap

    class Authenticator < ::Dry::Struct
      attr_reader :role_cls
      attr_reader :credentials_cls

      def initialize(env:,
                     ldap_server_factory: ::Authentication::AuthnLdap::Server,
                     role_cls: ::Authentication::MemoizedRole,
                     credentials_cls: ::Credentials)
        @env = env
        @filter = env['LDAP_FILTER'] || '(&(objectClass=posixAccount)(uid=%s))'
        @ldap_server = ldap_server_factory.new(
          uri:     env['LDAP_URI'],
          base:    env['LDAP_BASE'],
          bind_dn: env['LDAP_BINDDN'],
          bind_pw: env['LDAP_BINDPW']
        )
        @role_cls = role_cls
        @credentials_cls = credentials_cls
      end

      # Login the role using LDAP credentials
      def login(input)
        login, password = input.username, input.password

        # Prevent anonymous LDAP authentication with username only
        return nil if password.blank?

        # Prevent LDAP injection attack
        safe_login = Net::LDAP::Filter.escape(login)
        return nil if blacklisted_ldap_user?(safe_login)

        # Authenticate against LDAP
        filter = @filter % safe_login
        bind_results = @ldap_server.bind_as(filter: filter, password: password)
        return nil unless bind_results

        # Return Conjur API key
        role_id = role_cls.roleid_from_username(input.account, input.username)
        credentials_cls[role_id].api_key
      end

      # The current LDAP authenticator expects to authenticate using the Conjur API
      # key returned by LDAP login. To support backward compatibility, the LDAP
      # authenticator will still accept the LDAP credentials directly.
      def valid?(input)
        conjur_authenticator.valid?(input) ||
          !login(input).nil? # Deprecated, exists for backward compatibility
      end

      private

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
