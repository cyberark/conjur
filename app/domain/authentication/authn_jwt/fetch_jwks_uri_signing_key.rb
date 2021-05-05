require 'uri'
require 'net/http'

module Authentication
  module AuthnJwt
    # This class is responsible for fetching JWK Set from JWKS-uri
    class FetchJwksUriSigningKey < FetchSigningKeyInterface

      def initialize(authenticator_parameters,
                     logger,
                     discover_identity_provider,
                     fetch_required_secrets,
                     resource_class)
        @logger = logger
        @resource_id = authenticator_parameters.authenticator_resource_id
        @discover_identity_provider = discover_identity_provider
        @fetch_required_secrets = fetch_required_secrets
        @resource_class = resource_class
      end

      def has_valid_configuration?
        @jwks_resource_exists ||= jwks_uri_resource_exists?
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
        @jwks_uri_resource ||= resource(JWKS_URI_RESOURCE_NAME)
      end

      def resource(resource_name)
        @resource_class[resource_id(resource_name)]
      end

      def fetch_jwks_uri
        @logger.debug(LogMessages::Authentication::AuthnJwt::JwksUriResourceNameConfiguration.new(jwks_uri_resource_id))
        jwks_uri
      end

      def jwks_uri
        @jwks_uri ||= jwks_uri_secret[jwks_uri_resource_id]
      end

      def jwks_uri_secret
        @jwks_uri_secret ||= @fetch_required_secrets.(resource_ids: [jwks_uri_resource_id])
      end

      def jwks_uri_resource_id
        "#{@resource_id}/#{JWKS_URI_RESOURCE_NAME}"
      end

      def fetch_jwks_keys
        uri = URI(jwks_uri)
        @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingJwksFromJwksUri.new)
        response = Net::HTTP.get_response(uri)
        jwks = {
          keys: JSON.parse(response.body)['keys']
        }
        # TODO: algs should be set on ValidateAndDecode by the algorithm of the JWT itself
        algs = JWKS_ALGORITHM
        @logger.debug(LogMessages::Authentication::AuthnJwt::FetchJwksUriKeysSuccess.new)
        OAuth::ProviderKeys.new(jwks, algs)
      rescue => e
        raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
          jwks_uri,
          e.inspect
        )
      end
    end
  end
  end
