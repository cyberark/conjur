module Authentication
  module AuthnJwt
    class ConjurIdFromDecodedTokenProvider < IdProviderInterface

      attr_accessor :secret_fetcher

      def initialize(authentication_parameters)
        @resource_id = authentication_parameters.authenticator_resource_id
        @decoded_token = authentication_parameters.decoded_token
        @secret_fetcher = Conjur::FetchRequiredSecrets
      end

      def provide_jwt_id
        token_field_name = fetch_token_field_name
        if @decoded_token.include?(token_field_name)
          @decoded_token[token_field_name]
        else
          raise "No such field #{token_field_name} in the token"
        end
      end

      # Checks if variable that defined from which field in decoded token to get the id is configured
      def id_available?
        resource = ::Resource[token_id_field_resource_id]
        if resource
          return true
        end
        false
      end

      def token_id_field_resource_id
        "#{@resource_id}/#{JWT_ID_FIELD_NAME_VARIABLE}"
      end

      private

      def fetch_secret(secret_id)
        @secret_fetcher.new.(resource_ids: [secret_id])[secret_id]
      end

      def fetch_token_field_name
        resource_id = token_id_field_resource_id
        begin
          secret = fetch_secret(resource_id)
          if secret
            return secret.to_sym
          end
        rescue Errors::Conjur::RequiredSecretMissing
          raise "Variable #{JWT_ID_FIELD_NAME_VARIABLE} is configured but not populated with relevant secret"
        end
      end
    end
  end
end

