module Authentication
  module AuthnJwt
    module SigningKey
      # CreateJwksFromHttpResponse command class is responsible to create jwks object from http response
      CreateJwksFromHttpResponse ||= CommandClass.new(
        dependencies: {
          logger: Rails.logger,
          jwk_set_class: JSON::JWK::Set
        },
        inputs: %i[http_response]
      ) do
        def call
          validate_response_exists
          create_jwks_from_http_respnse
        end

        private

        def validate_response_exists
          raise Errors::Authentication::AuthnJwt::MissingHttpResponse if @http_response.blank?
        end

        def create_jwks_from_http_respnse
          @logger.debug(LogMessages::Authentication::AuthnJwt::CreatingJwksFromHttpResponse.new)

          raise Errors::Authentication::AuthnJwt::InvalidHttpResponseFormat unless @http_response.respond_to?(:body)

          response_body = @http_response.body
          encoded_body = Base64.encode64(response_body)
          jwks, keys = parse_jwks_response(response_body, encoded_body)

          if keys.blank?
            raise Errors::Authentication::AuthnJwt::FetchJwksUriKeysNotFound, encoded_body
          end

          @logger.debug(LogMessages::Authentication::AuthnJwt::CreatedJwks.new)
          jwks
        end

        def parse_jwks_response(response_body, encoded_body)
          parsed_response = JSON.parse(response_body)
          keys = parsed_response['keys']
          [{ keys: @jwk_set_class.new(keys) }, keys]
        rescue => e
          raise Errors::Authentication::AuthnJwt::FailedToConvertResponseToJwks.new(
            encoded_body,
            e.inspect
          )
        end
      end
    end
  end
end
