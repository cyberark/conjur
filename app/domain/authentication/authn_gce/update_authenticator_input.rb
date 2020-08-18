require 'command_class'

module Authentication
  module AuthnGce

    UpdateAuthenticatorInput = CommandClass.new(
      dependencies: {
        verify_and_decode_token: Authentication::OAuth::VerifyAndDecodeToken.new,
        decoded_token_class:     DecodedToken,
        logger:                  Rails.logger
      },
      inputs:       [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :authenticator_name, :account, :credentials, :username

      def call
        validate_token
        updated_input
      end

      private

      def validate_token
        decoded_token
        validate_audience
      end

      def decoded_token
        @decoded_token ||= @decoded_token_class.new(
          decoded_token_hash: @verify_and_decode_token.call(
            provider_uri:     PROVIDER_URI,
            token_jwt:        decoded_credentials.jwt,
            claims_to_verify: {
              verify_iss:        true,
              iss:               PROVIDER_URI,
              verify_iat:        true,
              verify_expiration: true
            }
          ),
          logger:             @logger
        )
      end

      def decoded_credentials
        @decoded_credentials ||= Authentication::Jwt::DecodedCredentials.new(credentials)
      end

      def validate_audience
        if audience_parts.length != 3 ||
          audience_parts[0] != "conjur" ||
          audience_parts[1] != account
          raise Errors::Authentication::AuthnGce::InvalidAudience, audience
        end
      end

      def audience_parts
        @audience_parts ||= audience.split('/', 3)
      end

      def audience
        @audience ||= @decoded_token.audience
      end

      def conjur_username
        return @conjur_username if @conjur_username

        @conjur_username = audience_parts[2]

        @logger.debug(
          LogMessages::Authentication::Jwt::ExtractedUsernameFromToken.new(
            conjur_username
          )
        )
        @conjur_username
      end

      def updated_input
        @authenticator_input.update(
          username: conjur_username,
          credentials: decoded_token
        )
      end
    end
  end
end
