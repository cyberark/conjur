require 'command_class'

module Authentication
  module AuthnGcp

    # Update the 'authenticator_input' object to include the username and the decoded token
    # The general 'Authenticate' command class performs validations on the user
    # so we need to first extract the username from the given token.
    # We also update the 'credentials' field in the 'authenticator_input' object
    # to include the decoded token instead of the original one so we don't need
    # to decode it again
    UpdateAuthenticatorInput = CommandClass.new(
      dependencies: {
        verify_and_decode_token: Authentication::OAuth::VerifyAndDecodeToken.new,
        validate_account_exists: Authentication::Security::ValidateAccountExists.new,
        decoded_token_class: DecodedToken,
        logger: Rails.logger
      },
      inputs: [:authenticator_input]
    ) do
      extend(Forwardable)
      def_delegators(:@authenticator_input, :authenticator_name, :account, :credentials, :username)

      def call
        validate_account_exists
        validate_token
        updated_input
      end

      private

      def validate_account_exists
        @validate_account_exists.(
          account: account
        )
      end

      def validate_token
        decoded_token
        validate_audience
      end

      def decoded_token
        @decoded_token ||= @decoded_token_class.new(
          decoded_token_hash: @verify_and_decode_token.call(
            provider_uri: PROVIDER_URI,
            token_jwt: decoded_credentials.jwt,
            claims_to_verify: {
              verify_iss: true,
              iss: PROVIDER_URI,
              verify_iat: true,
              verify_expiration: true
            },
            ca_cert: nil
          ),
          logger: @logger
        )
      end

      def decoded_credentials
        @decoded_credentials ||= Authentication::Jwt::DecodedCredentials.new(credentials)
      end

      def validate_audience
        if audience_parts.length != 3 ||
            audience_parts[0] != "conjur"
          raise Errors::Authentication::AuthnGcp::InvalidAudience, audience
        elsif audience_parts[1] != account
          raise Errors::Authentication::AuthnGcp::InvalidAccountInAudienceClaim.new(
            audience,
            audience_parts[1],
            account
          )
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
