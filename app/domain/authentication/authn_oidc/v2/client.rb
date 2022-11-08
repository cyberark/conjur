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
              revocation_endpoint: URI(discovery_information.raw["revocation_endpoint"]).path
            )
          end
        end

        def exchange_refresh_token_for_identity_token(refresh_token:, nonce:, include_refresh_token: false)
          extract_identity_token(
            bearer_token: retrieve_access_token(refresh_token: refresh_token),
            include_refresh_token: include_refresh_token
          )
        end

        def exchange_code_for_identity_token(code:, nonce:, code_verifier:, include_refresh_token: false)
          extract_identity_token(
            bearer_token: retrieve_access_token(code: code, additional_args: { code_verifier: code_verifier }),
            include_refresh_token: include_refresh_token
          )
        end

        # This is a bit of a weird method as we're using the refresh token to expire
        # the bearer token. This is necessary as we discard the bearer token once we
        # resolve the user.
        def logout(refresh_token:, nonce:)
          # TODO - need to handle failure in the below checks
          identity_and_token = exchange_refresh_token_for_identity_token(
            refresh_token: refresh_token,
            nonce: nonce,
            include_refresh_token: true
          )

          oidc_client.revoke!(refresh_token: refresh_token)
          oidc_client.revoke!(refresh_token: identity_and_token[:refresh_token])

          state = SecureRandom.hex(25)
          uri = URI(discovery_information.end_session_endpoint)
          uri.query = URI.encode_www_form(id_token_hint: id_token, state: state)

          # Call OIDC Logout endpoint
          # Ideally, the below functionality should be part of the `openid-connect` library.
          begin
          # TODO verify returned state matches that sent on logout request
            response = Net::HTTP.get_response(uri)
          rescue Exception => e
            # TODO handle exections
          end
        end

        # The methods below are internal methods.  They are not marked as private or
        # protected to allow them to be unit tested without going through the above
        # methods

        def extract_identity_token(bearer_token:, include_refresh_token:)
          id_token = bearer_token.id_token || bearer_token.access_token

          {
            id_token: verify_identity_token(id_token: id_token, nonce: nonce),
            refresh_token: include_refresh_token ? bearer_token.refresh_token : nil
          }
        end

        def retrieve_access_token(code: nil, refresh_token: nil, additional_args: {})
          if code.present?
            oidc_client.authorization_code = code
          elsif refresh_token.present?
            oidc_client.refresh_token = refresh_token
          end

          begin
            bearer_token = oidc_client.access_token!(
              scope: true,
              client_auth_method: :basic
            ).merge(additional_args)
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
          bearer_token
        end

        def verify_identity_token(id_token:, nonce:)
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

        # def get_token_with_code(code:, nonce:, code_verifier:)
        #   oidc_client.authorization_code = code
        #   id_token, refresh_token = get_token_pair(code_verifier)
        #   decoded_id_token = decode_id_token(id_token)
        #   verify_id_token(decoded_id_token, nonce)

        #   [decoded_id_token, refresh_token]
        # end

        # def get_token_with_refresh_token(refresh_token:, nonce:)
        #   oidc_client.refresh_token = refresh_token
        #   id_token, new_refresh_token = get_token_pair(nil)
        #   decoded_id_token = decode_id_token(id_token)
        #   verify_id_token(decoded_id_token, nonce, refresh: true)

        #   revoke(refresh_token) if new_refresh_token != refresh_token

        #   [decoded_id_token, new_refresh_token]
        # end

        # # Given a valid OIDC refresh token, nonce, state and redirect URI,
        # # this method revokes the provided (and updated, if applicable) refresh
        # # token(s), and constructs a URI to the OIDC provider's session
        # # termination endpoint.
        # def end_session(refresh_token:, nonce:, state:, redirect_uri:)
        #   oidc_client.refresh_token = refresh_token
        #   id_token, new_refresh_token = get_token_pair(nil)
        #   decoded_id_token = decode_id_token(id_token)
        #   verify_id_token(decoded_id_token, nonce, refresh: true)

        #   revoke(refresh_token)
        #   revoke(new_refresh_token) if new_refresh_token != refresh_token

        #   end_session_uri(
        #     id_token: id_token,
        #     state: state,
        #     redirect_uri: redirect_uri
        #   )
        # end

        # def end_session_uri(id_token:, state:, redirect_uri:)
        #   query = URI.encode_www_form(
        #     "id_token_hint" => id_token.to_s,
        #     "state" => state,
        #     "post_logout_redirect_uri" => redirect_uri
        #   )
        #   URI("#{discovery_information.end_session_endpoint}?#{query}")
        # end

        # def revoke(refresh_token)
        #   oidc_client.revoke!(refresh_token: refresh_token)
        # end

        # def get_token_pair(code_verifier)
        #   begin
        #     bearer_token = oidc_client.access_token!(
        #       scope: @authenticator.scope,
        #       client_auth_method: :basic,
        #       code_verifier: code_verifier
        #     )
        #   rescue Rack::OAuth2::Client::Error => e
        #     # Only handle the expected errors related to access token retrieval.
        #     case e.message
        #     when /PKCE verification failed/
        #       raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
        #             'PKCE verification failed'
        #     when /The authorization code is invalid or has expired/
        #       raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
        #             'Authorization code is invalid or has expired'
        #     when /The refresh token is invalid or expired/
        #       raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
        #             'Refresh token is invalid or has expired'
        #     end
        #     raise e
        #   end

        #   id_token = bearer_token.id_token || bearer_token.access_token
        #   refresh_token = bearer_token.refresh_token
        #   [id_token, refresh_token]
        # end

        # def decode_id_token(id_token)
        #   begin
        #     attempts ||= 0
        #     decoded_id_token = @oidc_id_token.decode(
        #       id_token,
        #       discovery_information.jwks
        #     )
        #   rescue Exception => e
        #     attempts += 1
        #     raise e if attempts > 1

        #     # If the JWKS verification fails, blow away the existing cache and
        #     # try again. This is intended to handle the case where the OIDC certificate
        #     # changes, and we want to cache the new certificate without decode failing.
        #     discovery_information(invalidate: true)
        #     retry
        #   end

        #   decoded_id_token
        # end

        # def verify_id_token(decoded_id_token, nonce, refresh: false)
        #   expected_nonce = nonce
        #   if refresh && decoded_id_token.raw_attributes['nonce'].nil?
        #     expected_nonce = nil
        #   end

        #   begin
        #     decoded_id_token.verify!(
        #       issuer: @authenticator.provider_uri,
        #       client_id: @authenticator.client_id,
        #       nonce: expected_nonce
        #     )
        #   rescue OpenIDConnect::ResponseObject::IdToken::InvalidNonce
        #     raise Errors::Authentication::AuthnOidc::TokenVerificationFailed,
        #           'Provided nonce does not match the nonce in the JWT'
        #   rescue OpenIDConnect::ResponseObject::IdToken::ExpiredToken
        #     raise Errors::Authentication::AuthnOidc::TokenVerificationFailed,
        #           'JWT has expired'
        #   rescue OpenIDConnect::ValidationFailed => e
        #     raise Errors::Authentication::AuthnOidc::TokenVerificationFailed,
        #           e.message
        #   end
        # end

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
