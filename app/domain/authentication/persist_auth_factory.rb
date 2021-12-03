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
        "Authentication::#{authenticator.underscore.camelize}::AuthenticatorData".constantize
      rescue
        raise ArgumentError, "Not implemented for authenticator #{authenticator}"
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
          raise ArgumentError, "Not implemented for authenticator #{authenticator}"
        end
      end
    end
  end
end
