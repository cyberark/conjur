require 'uri'
require 'net/http'
require 'base64'

module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for fetching JWK Set from JWKS-uri
      class FetchJwksUriSigningKey < FetchSigningKeyInterface

        def initialize(
          authentication_parameters:,
          fetch_required_secrets: Conjur::FetchRequiredSecrets.new,
          resource_class: ::Resource,
          http_lib: Net::HTTP,
          create_jwks_from_http_response: CreateJwksFromHttpResponse.new,
          logger: Rails.logger
        )
          @logger = logger

          @fetch_required_secrets = fetch_required_secrets
          @resource_class = resource_class
          @resource_id = authentication_parameters.authn_jwt_variable_id
          @http_lib = http_lib
          @create_jwks_from_http_response = create_jwks_from_http_response
        end

        def valid_configuration?
          return @valid_configuration if defined?(@valid_configuration)

          @valid_configuration = jwks_uri_resource_exists?
        end

        def fetch_signing_key
          fetch_jwks_uri
          fetch_jwks_keys
        end

        private

        def jwks_uri_resource_exists?
          !jwks_uri_resource.nil?
        end

        def jwks_uri_resource
          return @jwks_uri_resource if @jwks_uri_resource

          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingJwtConfigurationValue.new(jwks_uri_variable_id))

          @jwks_uri_resource = @resource_class[jwks_uri_variable_id]
        end

        def fetch_jwks_uri
          jwks_uri
        end

        def jwks_uri
          @jwks_uri ||= jwks_uri_secret[jwks_uri_variable_id]
        end

        def jwks_uri_secret
          @jwks_uri_secret ||= @fetch_required_secrets.(resource_ids: [jwks_uri_variable_id])
        end

        def jwks_uri_variable_id
          "#{@resource_id}/#{JWKS_URI_RESOURCE_NAME}"
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
