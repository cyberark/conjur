module Authentication
  module AuthnOidc

    class Authenticator

      # We don't need the env during the authentication process
      def self.requires_env_arg?
        false
      end

      # We actually don't have any specific validations for OIDC. We only verify
      # that the ID token is valid but this is done while it is decoded (using
      # a third-party). However, we want to verify that we verify the token no
      # matter what so we run the validation again (even if it means that in most
      # cases we will perform this action twice).
      #
      # The method is still defined because we need `valid?` to exist on the Authenticator
      # class so it is a valid Authenticator class
      def valid?(input)
        Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new.(
          authenticator_input: input
        )
      end

      def status(authenticator_status_input:)
        # The following is intended as a short-term fix for dealing
        # with two versions of the OIDC authenticator. In the medium
        # term, we need to port the V1 functionality to V2. Once that
        # is done, the following check can be removed.

        DB::Repository::AuthenticatorRepository.new.find(
          type: authenticator_status_input.authenticator_name,
          account: authenticator_status_input.account,
          service_id: authenticator_status_input.service_id
        ).bind do |authenticator_data|
          # check if this authenticator appears to be a Code Redirect authenticator
          if authenticator_data.key?(:client_id)
            Authentication::AuthnOidc::ValidateStatus.new(
              required_variable_names: %w[provider-uri client-id client-secret claim-mapping],
              optional_variable_names: %w[ca-cert]
            ).(
              account: authenticator_status_input.account,
              service_id: authenticator_status_input.service_id
            )

          # Otherwise, use the old style check
          else
            Authentication::AuthnOidc::ValidateStatus.new.(
              account: authenticator_status_input.account,
              service_id: authenticator_status_input.service_id
            )
          end
        end
      end
    end
  end
end
