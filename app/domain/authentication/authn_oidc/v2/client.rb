require 'uri'
require 'net/http'

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
              end_session_endpoint: URI(discovery_information.end_session_endpoint).path,
              revocation_endpoint: URI(discovery_information.raw['revocation_endpoint']).path
            )
          end
        end

        def exchange_refresh_token_for_tokens(refresh_token:, nonce:)
          tokens = extract_identity_and_refresh_tokens(
            bearer_token: get_bearer_token(refresh_token: refresh_token)
          )
          verify_identity_token(
            decoded_id_token: tokens[:id_token],
            nonce: nonce,
            refresh: true
          )
          tokens
        end

        def exchange_code_for_tokens(code:, nonce:, code_verifier:)
          tokens = extract_identity_and_refresh_tokens(
            bearer_token: get_bearer_token(code: code, code_verifier: code_verifier),
          )
          verify_identity_token(
            decoded_id_token: tokens[:id_token],
            nonce: nonce
          )
          tokens
        end

        # This method is meant to support RP-Initiated logout, where an end-
        # user's user-agent is redirected to the OIDC provider's
        # `end_session_endpoint`.
        #
        # This method needs to return both the OP's logout endpoint and a valid
        # identity token. Conjur needs to resolve the id token to a role for
        # audit logging.
        def exchange_refresh_token_for_logout_uri(refresh_token:, nonce:, state:, post_logout_redirect_uri:)
          tokens = exchange_refresh_token_for_tokens(
            refresh_token: refresh_token,
            nonce: nonce
          )

          oidc_client.revoke!(refresh_token: refresh_token)
          oidc_client.revoke!(refresh_token: tokens[:refresh_token])

          uri = URI(discovery_information.end_session_endpoint)
          uri.query = URI.encode_www_form({
            :id_token_hint => tokens[:raw_id_token],
            :state => state,
            :post_logout_redirect_uri => post_logout_redirect_uri
          }.compact)

          {
            :id_token => tokens[:id_token],
            :logout_uri => uri
          }
        end

        # The methods below are internal methods. They are not marked as
        # private to allow them to be unit tested without going through the
        # above methods.

        def extract_identity_and_refresh_tokens(bearer_token:)
          id_token = bearer_token.id_token || bearer_token.access_token
          {
            :id_token => decode_identity_token(id_token: id_token),
            :raw_id_token => id_token,
            :refresh_token => bearer_token.refresh_token
          }
        end

        def get_bearer_token(code: nil, refresh_token: nil, code_verifier: nil)
          if code.present?
            oidc_client.authorization_code = code
          elsif refresh_token.present?
            oidc_client.refresh_token = refresh_token
          end

          begin
            bearer_token = oidc_client.access_token!(
              scope: @authenticator.scope,
              client_auth_method: :basic,
              code_verifier: code_verifier
            )
          rescue Rack::OAuth2::Client::Error => e
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

          bearer_token
        end

        def decode_identity_token(id_token:)
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

        def verify_identity_token(decoded_id_token:, nonce:, refresh: false)
          # In token refresh flows, the OIDC provider should not include a nonce
          # value in the refreshed identity token, but if they do, it should be
          # validated.
          #
          # https://bitbucket.org/openid/connect/pull-requests/341/errata-clarified-nonce-during-id-token
          if refresh && decoded_id_token.nonce.nil?
            nonce = nil
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
        end

        def discovery_information(invalidate: false)
          @cache.fetch(
            "#{@authenticator.account}/#{@authenticator.service_id}/#{URI::Parser.new.escape(@authenticator.provider_uri)}",
            force: invalidate,
            skip_nil: true
          ) do
            @discovery_configuration.discover!(@authenticator.provider_uri)
          rescue Faraday::TimeoutError, Errno::ETIMEDOUT => e
            raise Errors::Authentication::OAuth::ProviderDiscoveryTimeout.new(@authenticator.provider_uri, e.message)
          rescue => e
            raise Errors::Authentication::OAuth::ProviderDiscoveryFailed.new(@authenticator.provider_uri, e.message)
          end
        end
      end
    end
  end
end
