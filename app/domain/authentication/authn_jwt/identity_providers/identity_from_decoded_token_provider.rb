module Authentication
  module AuthnJwt
    module IdentityProviders
      # Class for providing jwt identity from the decoded token from the field specified in a secret
      class IdentityFromDecodedTokenProvider < IdentityProviderInterface
        def initialize(
          authentication_parameters,
          fetch_required_secrets: Conjur::FetchRequiredSecrets.new,
          resource_class: ::Resource
        )
          @logger = Rails.logger

          @fetch_required_secrets= fetch_required_secrets
          @resource_class= resource_class
          @authentication_parameters = authentication_parameters
        end

        def jwt_identity
          return @jwt_identity if @jwt_identity

          token_field_name = fetch_token_field_name
          @logger.debug(LogMessages::Authentication::AuthnJwt::CheckingIdentityFieldExists.new(token_field_name))
          @jwt_identity ||= decoded_token[token_field_name]
          if @jwt_identity.blank?
            raise Errors::Authentication::AuthnJwt::NoSuchFieldInToken, token_field_name
          end

          @logger.debug(LogMessages::Authentication::AuthnJwt::FoundJwtFieldInToken.new(token_field_name, jwt_identity))
          @jwt_identity
        end

        # Checks if variable that defined from which field in decoded token to get the id is configured
        def identity_available?
          return @identity_available if defined?(@identity_available)

          @identity_available = identity_field_variable.present?
        end

        # This method is for the authenticator status check, unlike 'identity_available?' it checks if the
        # secret value is not empty too
        def identity_configured_properly?
          identity_available? && fetch_token_field_name.blank?
        end

        private

        def variable_id
          @authentication_parameters.authn_jwt_variable_id
        end

        def decoded_token
          @authentication_parameters.decoded_token
        end

        def identity_field_variable
          @resource_class[token_id_field_variable_id]
        end

        def fetch_token_field_name
          token_id_field_secret
        end

        def token_id_field_secret
          return @token_id_field_secret if @token_id_field_secret

          @token_id_field_secret = conjur_secret(token_id_field_variable_id)
          @logger.info(LogMessages::Authentication::AuthnJwt::RetrievedResourceValue.new(@token_id_field_secret, token_id_field_variable_id))
          @token_id_field_secret
        end

        def token_id_field_variable_id
          @token_id_field_variable_id ||= "#{variable_id}/#{TOKEN_APP_PROPERTY_VARIABLE}"
        end

        def conjur_secret(secret_id)
          @fetch_required_secrets.call(resource_ids: [secret_id])[secret_id]
        end
      end
    end
  end
end
