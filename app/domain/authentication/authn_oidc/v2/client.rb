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

        def get_token_with_code(code:, nonce:, code_verifier:)
          oidc_client.authorization_code = code
          id_token, refresh_token = get_token_pair(code_verifier)
          decoded_id_token = decode_id_token(id_token)
          verify_id_token(decoded_id_token, nonce)

          [decoded_id_token, refresh_token]
        end

        def get_token_with_refresh_token(refresh_token:, nonce:)
          oidc_client.refresh_token = refresh_token
          id_token, refresh_token = get_token_pair(nil)
          decoded_id_token = decode_id_token(id_token)
          verify_id_token(decoded_id_token, nonce, refresh: true)

          [decoded_id_token, refresh_token]
        end

        def get_token_pair(code_verifier)
          begin
            bearer_token = oidc_client.access_token!(
              scope: @authenticator.scope,
              client_auth_method: :basic,
              code_verifier: code_verifier
            )
          rescue Rack::OAuth2::Client::Error => e
            # Only handle the expected errors related to access token retrieval.
            case e.message
            when /PKCE verification failed/
              raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
                    'PKCE verification failed'
            when /The authorization code is invalid or has expired/
              raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
                    'Authorization code is invalid or has expired'
            when /The refresh token is invalid or expired/
              raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
                    'Refresh token is invalid or has expired'
            end
            raise e
          end

          id_token = bearer_token.id_token || bearer_token.access_token
          refresh_token = bearer_token.refresh_token
          [id_token, refresh_token]
        end

        def decode_id_token(id_token)
          begin
            attempts ||= 0
            decoded_id_token = @oidc_id_token.decode(
              id_token,
              discovery_information.jwks
            )
          rescue Exception => e
            attempts += 1
            raise e if attempts > 1

            # If the JWKS verification fails, blow away the existing cache and
            # try again. This is intended to handle the case where the OIDC certificate
            # changes, and we want to cache the new certificate without decode failing.
            discovery_information(invalidate: true)
            retry
          end

          decoded_id_token
        end

        def verify_id_token(decoded_id_token, nonce, refresh: false)
          expected_nonce = nonce
          if refresh && decoded_id_token.raw_attributes['nonce'].nil?
            expected_nonce = nil
          end

          begin
            decoded_id_token.verify!(
              issuer: @authenticator.provider_uri,
              client_id: @authenticator.client_id,
              nonce: expected_nonce
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
