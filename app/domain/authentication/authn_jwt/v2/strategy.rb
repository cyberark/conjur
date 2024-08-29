# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2
      class Strategy
        def initialize(
          authenticator:,
          http_client: ::Authentication::Util::NetworkTransporter,
          jwt_client: JWT,
          cache: Rails.cache,
          logger: Rails.logger,
          digest: Digest::SHA1
        )
          @authenticator = authenticator
          @http_client = http_client
          @jwt_client = jwt_client

          @logger = logger
          @cache = cache
          @digest = digest

          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        # rubocop:disable Lint/UnusedMethodArgument
        def callback(parameters:, request_body: nil)
          raise 'Not Implemented'
        end
        # rubocop:enable Lint/UnusedMethodArgument

        private

        def cache_key(url)
          # Include a digest of the url to ensure cache is expired if url changes
          @cache_key ||= "authenticators/#{@authenticator.type}/#{@authenticator.account}-#{@authenticator.service_id}/jwks-json-#{@digest.hexdigest(url)}"
        end

        def decode_jwt(jwt:, issuer: nil, audience: nil, jwks_uri: nil)
          jwt_args = {
            algorithms: %w[RS256 RS384 RS512],
            verify_iat: true
          }.tap do |args|
            if jwks_uri.present?
              args[:jwks] = jwk_loader(jwks_uri)
            end
            if issuer.present?
              args[:iss] = issuer
              args[:verify_iss] = true
            end
            if audience.present?
              args[:aud] = issuer
              args[:verify_aud] = true
            end
          end
          begin
            @success.new(
              @jwt_client.decode(
                jwt,
                nil,
                true, # Verify the signature of this token
                **jwt_args
              ).first
            )
          rescue => e
            @failure.new(e.message, exception: e, status: :bad_request)
          end
        end

        def jwk_loader(jwks_url)
          ->(options) { jwks(jwks_url: jwks_url, force: options[:invalidate]) || {} }
        end

        def fetch_jwks(url)
          client = @http_client.new(
            hostname: url,
            ca_certificate: @authenticator.ca_cert
          )
          result = client.get(url).bind do |response|
            return response
          end
          # Throw exception if we fail to retrieve the JWKS endpoint. This enables
          # us to break and prevent the cache from being created.
          raise result.error
        end

        # Caches the JWKS response. This will be expired if the key has
        # changed (and the signing key validation fails).
        def jwks(jwks_url:, force: false)
          @cache.fetch(cache_key(jwks_url), force: force, skip_nil: true) do
            fetch_jwks(jwks_url)
          end&.deep_symbolize_keys
        end
      end
    end
  end
end
