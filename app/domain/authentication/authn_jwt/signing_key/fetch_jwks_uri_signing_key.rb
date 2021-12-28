require 'uri'
require 'net/http'
require 'base64'

module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for fetching JWK Set from JWKS-uri
      class FetchJwksUriSigningKey

        def initialize(
          authenticator_input:,
          fetch_signing_key:,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          http_lib: Net::HTTP,
          create_jwks_from_http_response: CreateJwksFromHttpResponse.new,
          logger: Rails.logger
        )
          @logger = logger
          @http_lib = http_lib
          @create_jwks_from_http_response = create_jwks_from_http_response
          @fetch_authenticator_secrets = fetch_authenticator_secrets

          @authenticator_input = authenticator_input
          @fetch_signing_key = fetch_signing_key
        end

        def call(force_fetch:)
          @fetch_signing_key.call(
            refresh: force_fetch,
            cache_key: jwks_uri,
            signing_key_provider: self
          )
        end

        def fetch_signing_key
          fetch_jwks_uri
          fetch_jwks_keys
        end

        private

        def fetch_jwks_uri
          jwks_uri
        end

        def jwks_uri
          @jwks_uri ||= jwks_uri_secret
        end

        def jwks_uri_secret
          @jwks_uri_secret ||= @fetch_authenticator_secrets.call(
            conjur_account: @authenticator_input.account,
            authenticator_name: @authenticator_input.authenticator_name,
            service_id: @authenticator_input.service_id,
            required_variable_names: [JWKS_URI_RESOURCE_NAME]
          )[JWKS_URI_RESOURCE_NAME]
        end

        def fetch_jwks_keys
          begin
            uri = URI(jwks_uri)
            @logger.info(LogMessages::Authentication::AuthnJwt::FetchingJwksFromProvider.new(jwks_uri))
            response = @http_lib.get_response(uri)
            @logger.debug(LogMessages::Authentication::AuthnJwt::FetchJwtUriKeysSuccess.new)
          rescue => e
            raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
              jwks_uri,
              e.inspect
            )
          end

          @create_jwks_from_http_response.call(http_response: response)
        end
      end
    end
  end
end
