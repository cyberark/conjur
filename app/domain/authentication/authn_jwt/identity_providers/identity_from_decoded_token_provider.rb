module Authentication
  module AuthnJwt
    module IdentityProviders
      # Class for providing jwt identity from the decoded token from the field specified in a secret
      class IdentityFromDecodedTokenProvider < IdentityProviderInterface
        def initialize(authentication_parameters)
          @logger = Rails.logger

          @secret_fetcher = Conjur::FetchRequiredSecrets.new
          @resource_class = ::Resource
          @authentication_parameters = authentication_parameters
          @resource_id = @authentication_parameters.authn_jwt_variable_id
          @decoded_token = @authentication_parameters.decoded_token
        end

        def jwt_identity
          return @jwt_identity if @jwt_identity

          token_field_name = fetch_token_field_name
          @logger.debug(LogMessages::Authentication::AuthnJwt::CheckingIdentityFieldExists.new(token_field_name))
          @jwt_identity ||= @decoded_token[token_field_name]
          if @jwt_identity.blank?
            raise Errors::Authentication::AuthnJwt::NoSuchFieldInToken, token_field_name
          end

          @logger.debug(LogMessages::Authentication::AuthnJwt::FoundJwtFieldInToken.new(token_field_name, jwt_identity))
          @jwt_identity
        end

        # Checks if variable that defined from which field in decoded token to get the id is configured
        def identity_available
          return @identity_available unless @identity_available.nil?

          @identity_available ||= identity_field_variable.present?
        end

        # This method is for the authenticator status check, unlike 'identity_available?' it checks if the
        # secret value is not empty too
        def identity_configured_properly?
          fetch_token_field_name.blank? if identity_available
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
          secret = fetch_secret(resource_id)
          @logger.info(LogMessages::Authentication::AuthnJwt::RetrievedResourceValue.new(secret, resource_id))
          secret
        end
      end
    end
  end
end
