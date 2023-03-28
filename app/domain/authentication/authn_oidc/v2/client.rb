module Authentication
  module AuthnOidc
    module V2
      class Client
        def initialize(
          authenticator:,
          client: ::OpenIDConnect::Client,
          oidc_id_token: ::OpenIDConnect::ResponseObject::IdToken,
          discovery_configuration: ::OpenIDConnect::Discovery::Provider::Config,
          cache: Rails.cache,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @client = client
          @oidc_id_token = oidc_id_token
          @discovery_configuration = discovery_configuration
          @cache = cache
          @logger = logger
        end

        def oidc_client
          @oidc_client ||= begin
            issuer_uri = URI(@authenticator.provider_uri)
            @client.new(
              identifier: @authenticator.client_id,
              secret: @authenticator.client_secret,
              redirect_uri: @authenticator.redirect_uri,
              scheme: issuer_uri.scheme,
              host: issuer_uri.host,
              port: issuer_uri.port,
              authorization_endpoint: URI(discovery_information.authorization_endpoint).path,
              token_endpoint: URI(discovery_information.token_endpoint).path,
              userinfo_endpoint: URI(discovery_information.userinfo_endpoint).path,
              jwks_uri: URI(discovery_information.jwks_uri).path,
              end_session_endpoint: URI(discovery_information.end_session_endpoint).path
            )
          end
        end

        def callback(code:, nonce:, code_verifier: nil)
          oidc_client.authorization_code = code
          access_token_args = { scope: true, client_auth_method: :basic }
          access_token_args[:code_verifier] = code_verifier if code_verifier.present?
          begin
            bearer_token = oidc_client.access_token!(**access_token_args)
          rescue Rack::OAuth2::Client::Error => e
            # Only handle the expected errors related to access token retrieval.
            case e.message
            when /PKCE verification failed/
              raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
                    'PKCE verification failed'
            when /The authorization code is invalid or has expired/
              raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
                    'Authorization code is invalid or has expired'
            when /Code not valid/
              raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
                    'Authorization code is invalid'
            end
            raise e
          end
          id_token = bearer_token.id_token || bearer_token.access_token

          begin
            attempts ||= 0
            decoded_id_token = @oidc_id_token.decode(
              id_token,
              discovery_information.jwks
            )
          rescue StandardError => e
            attempts += 1
            raise e if attempts > 1

            # If the JWKS verification fails, blow away the existing cache and
            # try again. This is intended to handle the case where the OIDC certificate
            # changes, and we want to cache the new certificate without decode failing.
            discovery_information(invalidate: true)
            retry
          end

          begin
            decoded_id_token.verify!(
              issuer: @authenticator.provider_uri,
              client_id: @authenticator.client_id,
              nonce: nonce
            )
          rescue OpenIDConnect::ResponseObject::IdToken::InvalidNonce
            raise Errors::Authentication::AuthnOidc::TokenVerificationFailed,
                  'Provided nonce does not match the nonce in the JWT'
          rescue OpenIDConnect::ResponseObject::IdToken::ExpiredToken
            raise Errors::Authentication::AuthnOidc::TokenVerificationFailed,
                  'JWT has expired'
          rescue OpenIDConnect::ValidationFailed => e
            raise Errors::Authentication::AuthnOidc::TokenVerificationFailed,
                  e.message
          end
          decoded_id_token
        end

        def discovery_information(invalidate: false)
          @cache.fetch(
            "#{@authenticator.account}/#{@authenticator.service_id}/#{URI::Parser.new.escape(@authenticator.provider_uri)}",
            force: invalidate,
            skip_nil: true
          ) do
            @discovery_configuration.discover!(@authenticator.provider_uri)
          rescue HTTPClient::ConnectTimeoutError, Errno::ETIMEDOUT => e
            raise Errors::Authentication::OAuth::ProviderDiscoveryTimeout.new(@authenticator.provider_uri, e.message)
          rescue => e
            raise Errors::Authentication::OAuth::ProviderDiscoveryFailed.new(@authenticator.provider_uri, e.message)
          end
        end
      end
    end
  end
end
