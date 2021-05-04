require 'uri'
require 'net/http'

module Authentication
  module AuthnJwt

    JwtFetchJwksUriSigningKey = CommandClass.new(
      dependencies: {
        logger: Rails.logger,
        discover_identity_provider: OAuth::DiscoverIdentityProvider.new,
        fetch_secrets: Conjur::FetchRequiredSecrets.new
      },
      inputs: %i[authenticator_input]
    ) do
      def call
        jwks_uri
        fetch_jwks_keys
      end

      private

      def jwks_uri
        @logger.debug(LogMessages::Authentication::AuthnJwt::JwksUriResourceNameConfiguration.new(resource_id))
        @jwks_uri_secret ||= @fetch_secrets.(resource_ids: [resource_id])
        @jwks_uri ||=@jwks_uri_secret[resource_id]
      end

      def resource_id
        "#{@authenticator_input.account}:variable:conjur/#{@authenticator_input.authenticator_name}/#{@authenticator_input.service_id}/#{JWKS_URI_RESOURCE_NAME}"
      end

      def fetch_jwks_keys
        uri = URI(@jwks_uri)
        @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingJwksFromJwksUri.new)
        response = Net::HTTP.get_response(uri)
        jwks = {
          keys: JSON.parse(response.body)['keys']
        }
        # TODO: this field should be set on ValidateAndDecode by the algorithm of the JWT itself
        algs = ["RS256"]
        @logger.debug(LogMessages::Authentication::AuthnJwt::FetchJwksUriKeysSuccess.new)
        OAuth::ProviderKeys.new(jwks, algs)
      rescue => e
        raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
          @Jwks_uri,
          e.inspect
        )
      end
    end
  end
  end
