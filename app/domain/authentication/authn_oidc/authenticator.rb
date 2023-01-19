module Authentication
  module AuthnOidc

    class Authenticator

      # We don't need the env during the authentication process
      def self.requires_env_arg?
        false
      end

      # We actually don't have any specific validations for OIDC. We only verify
      # that the ID token is valid but this is done while it is decoded (using
      # a third-party). Thus, this method just returns true.
      #
      # The method is still defined because we need `valid?` to exist on the Authenticator
      # class so it is a valid Authenticator class
      def valid?(_input)
        true
      end

      def status(authenticator_status_input:)
        Authentication::AuthnOidc::ValidateStatus.new.(
          account: authenticator_status_input.account,
          service_id: authenticator_status_input.service_id
        )
      end
    end
  end
end
