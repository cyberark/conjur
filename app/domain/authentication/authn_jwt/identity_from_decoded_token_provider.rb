module Authentication
  module AuthnJwt
    # Class for providing jwt identity from the decoded token from the field specified in a secret
    class IdentityFromDecodedTokenProvider < IdentityProviderInterface
      def initialize(authentication_parameters)
        @resource_id = authentication_parameters.authenticator_resource_id
        @decoded_token = authentication_parameters.decoded_token
        @secret_fetcher = Conjur::FetchRequiredSecrets.new
        @resource_class = ::Resource
        @logger = Rails.logger
      end

      def provide_jwt_identity
        token_field_name = fetch_token_field_name
        @logger.debug(LogMessages::Authentication::AuthnJwt::LOOKING_FOR_IDENTITY_FIELD_NAME.new)
        jwt_identity = @decoded_token[token_field_name.to_sym]
        if jwt_identity.blank?
          raise Errors::Authentication::AuthnJwt::NoSuchFieldInToken.new(
            token_field_name
          )
        end
        jwt_identity
      end

      # Checks if variable that defined from which field in decoded token to get the id is configured
      def identity_available?
        identity_field_variable.present?
      end

      def identity_configured_properly?
        raise Errors::Authentication::AuthnJwt::IdentitySecretIsEmpty.new if fetch_token_field_name.blank?
      end

      private

      def identity_field_variable
        @resource_class[token_id_field_resource_id]
      end

      def token_id_field_resource_id
        "#{@resource_id}/#{IDENTITY_FIELD_VARIABLE}"
      end

      def fetch_secret(secret_id)
        @secret_fetcher.call(resource_ids: [secret_id])[secret_id]
      end

      def fetch_token_field_name
        resource_id = token_id_field_resource_id
        @logger.debug(LogMessages::Authentication::AuthnJwt::LOOKING_FOR_IDENTITY_FIELD_NAME.new(resource_id))
        fetch_secret(resource_id)
      end
    end
  end
end

