# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class OidcClient
        def initialize(
          authenticator:,
          client: NetworkTransporter,
          cache: Rails.cache,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @cache = cache
          @logger = logger

          @client = client.new(
            hostname: @authenticator.provider_uri,
            ca_certificate: @authenticator.ca_cert
          )

          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        def exchange(code:, nonce:, code_verifier: nil)
          exchange_token(code: code, nonce: nonce, code_verifier: code_verifier).bind do |bearer_token|
            decode_token(bearer_token).bind do |decoded_token|
              verify_token(token: decoded_token, nonce: nonce).bind do |verified_token|
                @success.new(verified_token)
              end
            end
          end
        end

        # 'jwks_uri' - GET
        # 'token_endpoint' - POST
        # Public method so strategy can call it to verify configuration
        def oidc_configuration
          @oidc_configuration ||= begin
            response = @client.get("#{@authenticator.provider_uri}/.well-known/openid-configuration").bind do |response|
              return @success.new(response)
            end
            @failure.new(
              "Authn-OIDC '#{@authenticator.service_id}' provider-uri: '#{@authenticator.provider_uri}' is unreachable",
              exception: Errors::Authentication::OAuth::ProviderDiscoveryFailed.new(
                @authenticator.provider_uri,
                response.message
              ),
              status: :unauthorized
            )
          end
        end

        private

        def exchange_token(code:, nonce:, code_verifier:)
          args = {
            grant_type: 'authorization_code',
            scope: true,
            code: code,
            nonce: nonce
          }
          args[:code_verifier] = code_verifier if code_verifier.present?
          args[:redirect_uri] = ERB::Util.url_encode(@authenticator.redirect_uri) if @authenticator.redirect_uri.present?

          oidc_configuration.bind do |config|
            response = @client.post(
              path: config['token_endpoint'],
              body: args.map { |k, v| "#{k}=#{v}" }.join('&'),
              basic_auth: [@authenticator.client_id, @authenticator.client_secret]
            ).bind do |token|
              bearer_token = token['id_token'] || token['access_token']
              return @success.new(bearer_token) if bearer_token.present?

              @failure.new(
                'Bearer Token is empty',
                exception: Errors::Authentication::AuthnOidc::TokenRetrievalFailed.new(response.message),
                status: :bad_request
              )
            end
            @failure.new(
              response.message,
              exception: Errors::Authentication::AuthnOidc::TokenRetrievalFailed.new(response.message),
              status: :bad_request
            )
          end
        end

        def decode_token(encoded_token)
          fetch_jwks.bind do |jwks|
            return @success.new(
              JWT.decode(
                encoded_token,
                nil,
                true, # Verify the signature of this token
                algorithms: %w[RS256 RS384 RS512],
                iss: @authenticator.provider_uri,
                verify_iss: true,
                aud: @authenticator.client_id,
                verify_aud: true,
                jwks: jwks
              ).first
            )
          end
        rescue => e
          @failure.new(e.message, exception: e, status: :bad_request)
        end

        def verify_token(token:, nonce:)
          unless token['nonce'] == nonce
            return @failure.new('nonce does not match')
          end

          @success.new(token)
        end

        def fetch_jwks
          oidc_configuration.bind do |configuration|
            @client.get(
              configuration['jwks_uri']
            ).bind do |response|
              @success.new(response)
            end
          rescue => e
            @failure.new(e.message, exception: e, status: :bad_request)
          end
        end
      end
    end
  end
end
