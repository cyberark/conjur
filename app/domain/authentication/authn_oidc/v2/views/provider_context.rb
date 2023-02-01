module Authentication
  module AuthnOidc
    module V2
      module Views
        class ProviderContext
          def initialize(
            client: Authentication::AuthnOidc::V2::Client,
            logger: Rails.logger
          )
            @client = client
            @logger = logger
          end

          def call(authenticators:)
            authenticators.map do |authenticator|
              {
                service_id: authenticator.service_id,
                type: 'authn-oidc',
                name: authenticator.name,
                redirect_uri: generate_redirect_url(
                  client: @client.new(authenticator: authenticator),
                  authenticator: authenticator
                )
              }
            end
          end

          def generate_redirect_url(client:, authenticator:)
            params = {
              client_id: authenticator.client_id,
              response_type: authenticator.response_type,
              scope: ERB::Util.url_encode(authenticator.scope),
              state: authenticator.state,
              nonce: authenticator.nonce,
              redirect_uri: ERB::Util.url_encode(authenticator.redirect_uri)
            }.map { |key, value| "#{key}=#{value}" }.join("&")

            "#{client.discovery_information.authorization_endpoint}?#{params}"
          end
        end
      end
    end
  end
end
