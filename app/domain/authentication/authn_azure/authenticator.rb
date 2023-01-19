require 'command_class'

module Authentication
  module AuthnAzure

    Authenticator = CommandClass.new(
      dependencies: {
        fetch_authenticator_secrets:    Authentication::Util::FetchAuthenticatorSecrets.new,
        verify_and_decode_token:        Authentication::OAuth::VerifyAndDecodeToken.new,
        validate_resource_restrictions: ValidateResourceRestrictions.new,
        logger:                         Rails.logger
      },
      inputs:       [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :service_id, :authenticator_name, :account, :credentials, :username

      def call
        validate_azure_token
        validate_resource_restrictions
      end

      private

      def validate_azure_token
        decoded_token
      end

      def decoded_token
        @decoded_token ||= DecodedToken.new(
          decoded_token_hash: @verify_and_decode_token.call(
            provider_uri:     provider_uri,
            token_jwt:        decoded_credentials.jwt,
            claims_to_verify: {
              verify_iss: true,
              iss:        provider_uri
            }
          ),
          logger:             @logger
        )
      end

      def decoded_credentials
        @decoded_credentials ||= Authentication::Jwt::DecodedCredentials.new(credentials)
      end

      def validate_resource_restrictions
        @validate_resource_restrictions.(
          service_id: service_id,
          account: account,
          username: username,
          xms_mirid_token_field: decoded_token.xms_mirid,
          oid_token_field: decoded_token.oid
        )
      end

      def provider_uri
        @provider_uri ||= azure_authenticator_secrets["provider-uri"].chomp('/') << '/'
      end

      def azure_authenticator_secrets
        @azure_authenticator_secrets ||= @fetch_authenticator_secrets.(
          service_id: service_id,
          conjur_account: account,
          authenticator_name: authenticator_name,
          required_variable_names: required_variable_names
        )
      end

      def required_variable_names
        @required_variable_names ||= %w(provider-uri)
      end
    end

    class Authenticator
      # This delegates to all the work to the call method created automatically
      # by CommandClass
      #
      # This is needed because we need `valid?` to exist on the Authenticator
      # class, but that class contains only a metaprogramming generated
      # `call(authenticator_input:)` method.  The methods we define in the
      # block passed to `CommandClass` exist only on the private internal
      # `Call` objects created each time `call` is run.
      def valid?(input)
        call(authenticator_input: input)
      end

      def status(authenticator_status_input:)
        Authentication::AuthnAzure::ValidateStatus.new.(
          account: authenticator_status_input.account,
          service_id: authenticator_status_input.service_id
        )
      end
    end
  end
end
