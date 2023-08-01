# frozen_string_literal: true

module Authentication
  # Allows creation of PersistAuth command class from an authenticator name
  class PersistAuthFactory
    class << self
      def new_from_authenticator(authenticator)
        Authentication::PersistAuth.new(
          auth_initializer: auth_initializer(authenticator).new,
          auth_data_class: auth_data_class(authenticator)
        )
      end

      private

      def auth_data_class(authenticator)
        case authenticator
        when "authn-k8s"
          Authentication::AuthnK8s::K8sAuthenticatorData
        when "authn-azure"
          Authentication::AuthnAzure::AzureAuthenticatorData
        when "authn-oidc"
          Authentication::AuthnOidc::OidcAuthenticatorData
        when "authn-gcp"
          Authentication::AuthnGcp::GcpAuthenticatorData
        when "authn-iam"
          Authentication::AuthnIam::IamAuthenticatorData
        when "authn-ldap"
          Authentication::AuthnLdap::LdapAuthenticatorData
        else
          raise ArgumentError, format("Not implemented for authenticator %s", authenticator)
        end
      end

      def auth_initializer(authenticator)
        case authenticator
        when "authn-k8s"
          Authentication::AuthnK8s::InitializeK8sAuth
        when "authn-azure"
          Authentication::Default::InitializeDefaultAuth
        when "authn-oidc"
          Authentication::Default::InitializeDefaultAuth
        when "authn-gcp"
          Authentication::Default::InitializeDefaultAuth
        when "authn-iam"
          Authentication::Default::InitializeDefaultAuth
        when "authn-ldap"
          Authentication::Default::InitializeDefaultAuth
        else
          raise ArgumentError, format("Not implemented for authenticator %s", authenticator)
        end
      end
    end
  end

  # Allows creation of AuthHostDetails class from an authenticator name
  class AuthHostDetailsFactory
    class << self
      def new_from_authenticator(authenticator, json_data)
        Authentication::AuthHostDetails.new(json_data, constraints: constraints(authenticator))
      end

      private

      def constraints(authenticator)
        case authenticator
        when "authn-k8s"
          Authentication::AuthnK8s::Restrictions::CONSTRAINTS
        when "authn-oidc"
          nil
        when "authn-azure"
          Authentication::AuthnAzure::Restrictions::CONSTRAINTS
        when "authn-gcp"
          Authentication::AuthnGcp::Restrictions::CONSTRAINTS
        when "authn-iam"
          nil
        when "authn-ldap"
          nil
        else
          raise ArgumentError, format("Not implemented for authenticator %s", authenticator)
        end
      end
    end
  end
end
