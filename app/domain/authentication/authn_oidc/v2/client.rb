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

        def refresh(refresh_token:)
          unless refresh_token.present?
            raise Errors::Authentication::RequestBody::MissingRequestParam, 'refresh_token'
          end

          oidc_client.refresh_token = refresh_token
          get_token_pair(nonce: nil)
        end

        def callback(code:)
          unless code.present?
            raise Errors::Authentication::RequestBody::MissingRequestParam, 'code'
          end

          oidc_client.authorization_code = code
          get_token_pair(nonce: @authenticator.nonce)
        end

        def get_token_pair(nonce:)
          bearer_token = oidc_client.access_token!(
            scope: @authenticator.scope,
            client_auth_method: :basic,
            nonce: nonce
          )
          id_token = bearer_token.id_token || bearer_token.access_token
          refresh_token = bearer_token.refresh_token
          return decode_id_token(id_token, nonce), refresh_token
        end

        def decode_id_token(id_token, expected_nonce)
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

          decoded_id_token.verify!(
            issuer: @authenticator.provider_uri,
            client_id: @authenticator.client_id,
            nonce: expected_nonce
          )
          decoded_id_token
        rescue OpenIDConnect::ValidationFailed => e
          raise Errors::Authentication::AuthnOidc::TokenVerificationFailed, e.message
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
