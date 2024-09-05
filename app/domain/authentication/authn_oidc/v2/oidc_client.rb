# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class OidcClient
        def initialize(
          authenticator:,
          client: Authentication::Util::NetworkTransporter,
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

        # 'jwks_uri' - GET
        # 'token_endpoint' - POST
        # Public method so strategy can call it to verify configuration
        def oidc_configuration
          @oidc_configuration ||= begin
            response = @client.get("#{@authenticator.provider_uri}/.well-known/openid-configuration").bind do |success|
              return @success.new(success)
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

        def exchange_code_for_token(code:, nonce:, code_verifier: nil)
          args = {
            grant_type: 'authorization_code',
            scope: @authenticator.scope,
            code: code,
            nonce: nonce
          }
          args[:code_verifier] = code_verifier if code_verifier.present?
          args[:redirect_uri] = @authenticator.redirect_uri if @authenticator.redirect_uri.present?

          oidc_configuration.bind do |config|
            response = @client.post(
              path: config['token_endpoint'],
              body: args,
              basic_auth: [@authenticator.client_id, @authenticator.client_secret],
              headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
            ).bind do |token|
              bearer_token = token['id_token'] || token['access_token']
              return @success.new(bearer_token) if bearer_token.present?

              return @failure.new(
                'Bearer Token is empty',
                exception: Errors::Authentication::AuthnOidc::TokenRetrievalFailed.new('Bearer Token is empty'),
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
      end
    end
  end
end
