
module Authentication
  module AuthnOidc
    module V2
      class Strategy
        def initialize(
          authenticator:,
          oidc_client: ::OpenIDConnect::Client,
          oidc_id_token: ::OpenIDConnect::ResponseObject::IdToken,
          discovery_configuration: ::OpenIDConnect::Discovery::Provider::Config
        )
          @authenticator = authenticator
          @oidc_client = oidc_client
          @oidc_id_token = oidc_id_token
          @discovery_configuration = discovery_configuration
        end

        # Don't love this name...
        def callback(parameters:)
          # TODO: Check that `code` and `state` attributes are present
          raise 'State is different' if parameters[:state] != @authenticator.state

          retrieve_identity(
            jwt: retrieve_jwt(
              code: parameters[:code]
            )
          )
        end

        def retrieve_jwt(code:)
          client.authorization_code = code
          id_token = client.access_token!(
            scope: true,
            client_auth_method: :basic,
            nonce: @authenticator.nonce
          ).id_token

          decoded_id_token = @oidc_id_token.decode(
            id_token,
            discovery_information.jwks
          )

          # TODO: Create a robust JWT verifier based on https://blog.unathichonco.com/verifying-jwts-with-jwks-in-ruby
          decoded_id_token.verify!(
            issuer: @authenticator.provider_uri,
            client_id: @authenticator.client_id,
            nonce: @authenticator.nonce
          )
          decoded_id_token
        rescue OpenIDConnect::ValidationFailed => e
          raise Errors::Authentication::AuthnOidc::TokenVerificationFailed, e.message
        end

        def retrieve_identity(jwt:)
          jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
        end

        # def generate_login_url
        # # def setup(authenticator)
        #   @authenticator.redirect_parameters.map { |key, value| "#{key}=#{value}" }.join("&")

        #   "#{oidc_util(authenticator).discovery_information.authorization_endpoint}?#{params}"
        # end

        def client
          # Internal methods
          @client ||= begin
            issuer_uri = URI(@authenticator.provider_uri)
            @oidc_client.new(
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

        def discovery_information
          Rails.cache.fetch(
            "#{@authenticator.account}/#{@authenticator.service_id}/#{URI::Parser.new.escape(@authenticator.provider_uri)}",
            expires_in: 5.minutes
          ) do
            @discovery_configuration.discover!(@authenticator.provider_uri)
          rescue HTTPClient::ConnectTimeoutError, Errno::ETIMEDOUT => e
            raise Errors::Authentication::OAuth::ProviderDiscoveryTimeout.new(@authenticator.provider_uri, e.inspect)
          rescue => e
            raise Errors::Authentication::OAuth::ProviderDiscoveryFailed.new(@authenticator.provider_uri, e.inspect)
          end
        end
      end
    end
  end
end
