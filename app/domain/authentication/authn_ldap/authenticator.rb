# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'net/ldap'

module Authentication
  module AuthnLdap
    class Authenticator
      def initialize(env:,
                     ldap_server_factory: ::Authentication::AuthnLdap::Server,
                     ldap_server_configuration: ::Authentication::AuthnLdap::Configuration,
                     conjur_authenticator: ::Authentication::Authn::Authenticator,
                     role_cls: Role,
                     credentials_cls: ::Credentials)
        @env = env
        @ldap_server_factory = ldap_server_factory
        @ldap_server_configuration = ldap_server_configuration
        @conjur_authenticator = conjur_authenticator
        @role_cls = role_cls
        @credentials_cls = credentials_cls
      end

      # Login the role using LDAP credentials
      def login(input)
        login, password = input.username, input.credentials

        # Prevent anonymous LDAP authentication with username only
        return nil if password.blank?

        # Prevent LDAP injection attack
        safe_login = Net::LDAP::Filter.escape(login)
        return nil if blacklisted_ldap_user?(safe_login)

        # Authenticate against LDAP
        filter = ldap_configuration(input).filter_template % safe_login
        bind_results = ldap_server(input).bind_as(filter: filter, password: password)
        return nil unless bind_results

        # Return Conjur API key
        role_id = @role_cls.roleid_from_username(input.account, input.username)
        @credentials_cls[role_id].api_key
      end

      # The current LDAP authenticator expects to authenticate using the Conjur API
      # key returned by LDAP login. To support backward compatibility, the LDAP
      # authenticator will still accept the LDAP credentials directly.
      def valid?(input)
        @conjur_authenticator.new.valid?(input) ||
          !login(input).nil? # Deprecated, exists for backward compatibility
      end

      private

      def ldap_server(input)
        @ldap_server_factory.new(ldap_configuration(input))
      end

      def ldap_configuration(input)
        @ldap_server_configuration.new(input, @env)
      end

      # admin should only be able to login through plain Conjur authn
      def blacklisted_ldap_user?(login)
        login == 'admin'
      end
    end
  end
end
