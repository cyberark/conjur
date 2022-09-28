require 'jwt'

module Authentication
  module AuthnJwt
    module V2
      class Strategy
        REQUIRED_PARAMS = [].freeze

        def initialize(
          authenticator:,
          jwt: JWT,
          json: JSON,
          http: HTTP,
          cache: Rails.cache,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @jwt = jwt
          @logger = logger
          @cache = cache
          @http = http
          @json = json
          @cache_key = "#{@authenticator.account}/auth-jwks/#{authenticator.service_id}/jwks-json".freeze
        end

        # Don't love this name...
        def callback(params)
          # binding.pry

          decoded_token = @jwt.decode(
            params[:body],
            nil,
            true, # Verify the signature of this token
            algorithms: @authenticator.algorithms,
            iss: @authenticator.issuer,
            verify_iss: true,
            aud: @authenticator.audience,
            verify_aud: true,
            jwks: jwk_loader
          )
          # Return the data portion of the decoded JWT
          [*decoded_token].first
        end

        private

        def jwk_loader
          ->(options) do
            jwks(force: options[:invalidate]) || {}
          end
        end

        def fetch_jwks
          response = @http.get(@authenticator.jwks_uri)
          if response.code == 200
            @json.parse(response.body.to_s)
          end
        end

        def jwks(force: false)
          @cache.fetch(@cache_key, force: force, skip_nil: true) do
            fetch_jwks
          end&.deep_symbolize_keys
        end
      end
    end
  end
end
