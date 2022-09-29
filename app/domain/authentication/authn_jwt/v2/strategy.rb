require 'jwt'
require 'net/http'

module Authentication
  module AuthnJwt
    module V2
      class Strategy
        REQUIRED_PARAMS = [].freeze

        def initialize(
          authenticator:,
          jwt: JWT,
          json: JSON,
          http: Net::HTTP,
          cache: Rails.cache,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @jwt = jwt
          @logger = logger
          @cache = cache
          @http = http
          @json = json
          @cache_key = "#{@authenticator.account}/auth-jwks/#{authenticator.service_id}/jwks-json"
        end

        # Don't love this name...
        def callback(params)
          # binding.pry

          decoded_token = @jwt.decode(
            params[:body].split('=').last,
            nil,
            true, # Verify the signature of this token
            algorithms: @authenticator.algorithms,
            iss: @authenticator.issuer,
            verify_iss: @authenticator.issuer.present?,
            aud: @authenticator.audience,
            verify_aud: @authenticator.audience.present?,
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
          # binding.pry
          response = @http.get_response(URI(@authenticator.jwks_uri))
          if response.code == '200'
            @json.parse(response.body)
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
